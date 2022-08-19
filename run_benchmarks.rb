#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'fileutils'
require 'shellwords'
require 'csv'
require 'json'
require 'rbconfig'
require 'etc'

WARMUP_ITRS = 15

# Check which OS we are running
def os
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    else
      raise "unknown os: #{host_os.inspect}"
    end
  )
end

# Checked system - error if the command fails
def check_call(command, verbose: false)
  puts(command)

  if verbose
    status = system(command, out: $stdout, err: :out)
  else
    status = system(command)
  end

  unless status
    puts "Command #{command.inspect} failed in directory #{Dir.pwd}"
    raise RuntimeError.new
  end
end

def check_output(command)
  IO.popen(command).read
end

def build_yjit(repo_dir)
  if !File.exist?(repo_dir)
    puts("Directory does not exist \"#{repo_dir}\"")
    exit(-1)
  end

  Dir.chdir(repo_dir) do
    check_call("git pull")

    # Don't do a clone and configure every time
    # ./config.status --config => check that DRUBY_DEBUG is not in there
    config_out = check_output("./config.status --config")

    if config_out.include?("DRUBY_DEBUG")
      puts("WARNING: You should configure YJIT in release mode for benchmarking")
      #exit(-1)
    end

    # Build in parallel
    #n_cores = os.cpu_count()
    n_cores = 32
    puts("Building YJIT with #{n_cores} processes")
    check_call("make -j#{n_cores} install")
  end
end

def set_bench_config()
  # Only available on intel systems
  if File.exist?('/sys/devices/system/cpu/intel_pstate')
    # sudo requires the flag '-S' in order to take input from stdin
    check_call("sudo -S sh -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'")
    check_call("sudo -S sh -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct'")
  end
end

def check_chruby()
  ruby = RbConfig.ruby
  ruby_version = check_output("#{ruby} -v --yjit").strip

  if !ruby_version.downcase.include?("yjit")
    puts "Your current Ruby (#{ruby}) doesn't seem to include YJIT."
    puts "Maybe you need to chruby to ruby-yjit?"
    puts "  chruby ruby-yjit"
    exit(-1)
  end
end

def get_ruby_version(repo_dir)
  ruby_version = {}

  ruby_version[:ruby_version] = RUBY_DESCRIPTION

  Dir.chdir(repo_dir) do
    ruby_version[:git_branch] = check_output("git branch --show-current").strip
    ruby_version[:git_commit] = check_output("git log --pretty=format:%h -n 1").strip
  end

  return ruby_version
end

def check_pstate()
  # Only available on intel systems
  if !File.exist?('/sys/devices/system/cpu/intel_pstate/no_turbo')
    return
  end

  File.open('/sys/devices/system/cpu/intel_pstate/no_turbo', mode='r') do |file|
    if file.read.strip != '1'
      puts("You forgot to disable turbo:")
      puts("  sudo sh -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'")
      exit(-1)
    end
  end

  if !File.exist?('/sys/devices/system/cpu/intel_pstate/min_perf_pct')
    return
  end

  File.open('/sys/devices/system/cpu/intel_pstate/min_perf_pct', mode='r') do |file|
    if file.read.strip != '100'
      puts("You forgot to set the min perf percentage to 100:")
      puts("  sudo sh -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct'")
      exit(-1)
    end
  end
end

def table_to_str(table_data, format)
  # Trim numbers to one decimal for console display
  # Keep two decimals for the speedup ratios

  table_data = table_data.first(1) + table_data.drop(1).map { |row|
    format.zip(row).map { |fmt, data| fmt % data }
  }

  num_rows = table_data.length
  num_cols = table_data[0].length

  # Pad each column to the maximum width in the column
  (0...num_cols).each do |c|
    cell_lens = (0...num_rows).map { |r| table_data[r][c].length }
    max_width = cell_lens.max
    (0...num_rows).each { |r| table_data[r][c] = table_data[r][c].ljust(max_width) }
  end

  # Row of separator dashes
  sep_row = (0...num_cols).map { |i| '-' * table_data[0][i].length }.join('  ')

  out = sep_row + "\n"

  table_data.each do |row|
    out += row.join('  ') + "\n"
  end

  out += sep_row

  return out
end

def mean(values)
  return values.sum(0.0) / values.size
end

def stddev(values)
  xbar = mean(values)
  diff_sqrs = values.map { |v| (v-xbar)*(v-xbar) }
  mean_sqr = diff_sqrs.sum(0.0) / values.length
  return Math.sqrt(mean_sqr)
end

def free_file_no(prefix)
  (1..1000).each do |file_no|
    out_path = File.join(prefix, "output_%03d.csv" % file_no)
    if !File.exist?(out_path)
      return file_no
    end
  end
  assert false
end

# Check if the name matches any of the names in a list of filters
def match_filter(name, filters)
  if filters.length == 0
    return true
  end

  filters.each do |filter|
    if name.downcase.include?(filter)
      return true
    end
  end

  return false
end

# Run all the benchmarks and record execution times
def run_benchmarks(ruby_opts, name_filters, out_path)
  bench_times = {}

  # Get the list of benchmark files/directories matching name filters
  bench_files = Dir.children('benchmarks').sort.filter do |entry|
    match_filter(entry, name_filters)
  end

  bench_files.each_with_index do |entry, idx|
    bench_name = entry.gsub('.rb', '')

    puts("Running benchmark \"#{bench_name}\" (#{idx+1}/#{bench_files.length})")

    # Path to the benchmark runner script
    script_path = File.join('benchmarks', entry)

    if !script_path.end_with?('.rb')
      script_path = File.join(script_path, 'benchmark.rb')
    end

    # Set up the environment for the benchmarking command
    ENV["OUT_CSV_PATH"] = File.join(out_path, 'temp.csv')
    ENV["WARMUP_ITRS"] = WARMUP_ITRS.to_s

    # Set up the benchmarking command
    cmd = []
    if os == :linux
      cmd += [
        # Disable address space randomization (for determinism)
        "setarch", "x86_64", "-R",
        # Pin the process to one given core to improve caching
        "taskset", "-c", "#{Etc.nprocessors - 1}",
      ]
    end
    cmd += [
      "ruby",
      "-I", "./harness",
      ruby_opts,
      script_path,
    ]

    # Do the benchmarking
    check_call(cmd.join(' '))

    # Read the benchmark data
    # Convert times to ms
    ruby_description, *times = File.readlines(ENV["OUT_CSV_PATH"])
    times = times.map { |v| 1000 * Float(v) }
    bench_times[bench_name] = times
  end

  return bench_times
end

# Default values for command-line arguments
args = OpenStruct.new({
  repo_dir: "../yjit",
  out_path: "./data",
  yjit_opts: "",
  name_filters: []
})

OptionParser.new do |opts|
  #opts.banner = "Usage: example.rb [options]"
  opts.on("--repo_dir=REPO_DIR") do |v|
    args.repo_dir = v
  end

  opts.on("--out_path=OUT_PATH", "directory where to store output data files") do |v|
    args.out_path = v
  end

  opts.on("--name_filters=x,y,z", Array, "when given, only benchmarks with names that contain one of these strings will run") do |list|
    args.name_filters = list
  end

  opts.on("--yjit_opts=OPT_STRING", "string of command-line options to run YJIT with") do |str|
    args.yjit_opts=str
  end
end.parse!

# Remaining arguments are treated as benchmark name filters
if ARGV.length > 0
  args.name_filters += ARGV
end

# Check that the chruby command was run
# Note: we intentionally do this first
check_chruby()

# Disable CPU frequency scaling
set_bench_config()

# Check pstate status
check_pstate()

# Create the output directory
FileUtils.mkdir_p(args.out_path)

# Get the ruby binary version string
ruby_version = get_ruby_version(args.repo_dir)

# Benchmark with and without YJIT
bench_start_time = Time.now.to_f
yjit_times = run_benchmarks(ruby_opts="--yjit #{args.yjit_opts}", name_filters=args.name_filters, out_path=args.out_path)
interp_times = run_benchmarks(ruby_opts="--disable-yjit", name_filters=args.name_filters, out_path=args.out_path)
bench_end_time = Time.now.to_f
bench_names = yjit_times.keys.sort

bench_total_time = (bench_end_time - bench_start_time).to_i
puts("Total time spent benchmarking: #{bench_total_time}s")
puts()

# Table for the data we've gathered
table  = [["bench", "interp (ms)", "stddev (%)", "yjit (ms)", "stddev (%)", "interp/yjit", "yjit 1st itr"]]
format =  ["%s",    "%.1f",        "%.1f",       "%.1f",      "%.1f",        "%.2f",        "%.2f"]

# Format the results table
bench_names.each do |bench_name|
  yjit_t = yjit_times[bench_name]
  interp_t = interp_times[bench_name]

  yjit_t0 = yjit_t[0]
  yjit_t = yjit_t[WARMUP_ITRS..]
  interp_t0 = interp_t[0]
  interp_t = interp_t[WARMUP_ITRS..]
  ratio_1st = interp_t0 / yjit_t0
  ratio = mean(interp_t) / mean(yjit_t)

  table.append([
    bench_name,
    mean(interp_t),
    100 * stddev(interp_t) / mean(interp_t),
    mean(yjit_t),
    100 * stddev(yjit_t) / mean(yjit_t),
    ratio,
    ratio_1st,
  ])
end

# Find a free file index for the output files
file_no = free_file_no(args.out_path)

metadata = {
  'end_time': Time.now.strftime("%Y-%m-%d %H:%M:%S %Z (%z)"),
  'yjit_opts': args.yjit_opts,
}

ruby_version.each do |k, v|
    metadata[k] = v
end

# Save the raw data as JSON
out_json_path = File.join(args.out_path, "output_%03d.json" % file_no)
File.open(out_json_path, "w") do |file|
  out_data = {
    'metadata': metadata,
    'yjit': yjit_times,
    'interp': interp_times,
  }
  json_str = JSON.generate(out_data)
  file.write json_str
end

# Save data as CSV so we can produce tables/graphs in a spreasheet program
# NOTE: we don't do any number formatting for the output file because
#       we don't want to lose any precision
output_rows = []
metadata.each do |key, value|
  output_rows.append([key, value])
end
output_rows.append([])
output_rows.concat(table)
out_tbl_path = File.join(args.out_path, 'output_%03d.csv' % file_no)
CSV.open(out_tbl_path, "wb") do |csv|
  output_rows.each do |row|
    csv << row
  end
end

# Save the output in a text file that we can easily refer to
output_str = ""
metadata.each do |key, value|
  output_str += "#{key}=\"#{value}\"\n"
end
output_str += "\n"
output_str += table_to_str(table, format) + "\n"
output_str += "Legend:\n"
output_str += "- interp/yjit: ratio of interp/yjit time. Higher is better. Above 1 represents a speedup.\n"
output_str += "- 1st itr: ratio of interp/yjit time for the first benchmarking iteration.\n"
out_txt_path = File.join(args.out_path, "output_%03d.txt" % file_no)
File.open(out_txt_path, "w") { |f| f.write output_str }

# Print the table to the console, with numbers truncated
puts(output_str)
