#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'fileutils'
require 'shellwords'
require 'csv'
require 'json'

def check_call(args)
    command = (args.kind_of?(Array)) ? (args.shelljoin):args
    status = system(command)
    raise RuntimeError unless status
end

def check_output(args)
    IO.popen(args).read
end

def build_yjit(repo_dir)
    if !File.exist?(repo_dir)
        puts("Directory does not exist \"#{repo_dir}\"")
        exit(-1)
    end

    Dir.chdir(repo_dir) do
        check_call(['git', 'pull'])

        # Don't do a clone and configure every time
        # ./config.status --config => check that DRUBY_DEBUG is not in there
        config_out = check_output(['./config.status', '--config'])

        if config_out.include?("DRUBY_DEBUG")
            puts("You should configure YJIT in release mode for benchmarking")
            exit(-1)
        end

        # Build in parallel
        #n_cores = os.cpu_count()
        n_cores = 32
        puts("Building YJIT with #{n_cores} processes")
        check_call(["make", "-j#{n_cores}", "install"])
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

def get_ruby_version(repo_dir)
    ruby_version = check_output(["ruby", "-v"]).strip

    if !ruby_version.downcase.include?("yjit")
        puts("You forgot to chruby to ruby-yjit:")
        puts("  chruby ruby-yjit")
        exit(-1)
    end

    Dir.chdir(repo_dir) do
        branch_name = check_output(['git', 'branch', '--show-current']).strip
        ruby_version += "\ngit branch #{branch_name}"
        commit_hash = check_output(['git', 'log', "--pretty=format:%h", '-n', '1']).strip
        ruby_version += "\ngit commit hash #{commit_hash}"
    end

    puts(ruby_version)

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

def table_to_str(table_data)
    def trim_cell(cell, num_decimals)
        begin
            case num_decimals
            when 1
                return "%.1f" % cell
            when 2
                return "%.2f" % cell
            else
                raise RuntimeError
            end
        rescue
            return cell
        end
    end

    # Trim numbers to one decimal for console display
    # Keep two decimals for the speedup ratio
    trim_1dec = Proc.new { |c| trim_cell(c, 1) }
    trim_2dec = Proc.new { |c| trim_cell(c, 2) }
    table_data = table_data.map { |row| row[..-2].map(trim_1dec) + row[-1..].map(trim_2dec) }

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

def free_file_no(out_path)
    (1..1000).each do |file_no|
        out_path = File.join(out_path, "output_%03d.csv" % file_no)
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
def run_benchmarks(enable_yjit, name_filters, out_path)
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

        # Set up the benchmarking command
        cmd = [
            # Disable address space randomization (for determinism)
            "setarch", "x86_64", "-R",
            # Pin the process to one given core to improve caching
            "taskset", "-c", "11",
            # Run the benchmark
            "ruby",
            enable_yjit ? "--yjit":"--disable-yjit",
            "-I", "./harness",
            script_path
        ]

        # Do the benchmarking
        puts(cmd.join(' '))
        check_call(cmd)

        # Read the benchmark data
        # Convert times to ms
        rows = CSV.read(ENV["OUT_CSV_PATH"])
        times = rows[0].map { |v| 1000 * v.to_f }
        times = times.sort
        bench_times[bench_name] = times
    end

    return bench_times
end

# Default values for command-line arguments
args = OpenStruct.new({
    repo_dir: "../yjit",
    out_path: "./data",
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

  opts.on("--out_path=OUT_PATH") do |v|
    args[:out_path] = v
  end

end.parse!

# Remaining arguments are treated as benchmark name filters
if ARGV.length > 0
    args.name_filters += ARGV
end

# Create the output directory
FileUtils.mkdir_p(args.out_path)

# Update and build YJIT
build_yjit(args.repo_dir)

# Disable CPU frequency scaling
set_bench_config()

# Get the ruby binary version string
ruby_version = get_ruby_version(args.repo_dir)

# Check pstate status
check_pstate()

# Benchmark with and without YJIT
bench_start_time = Time.now.to_f
yjit_times = run_benchmarks(enable_yjit=true, name_filters=args.name_filters, out_path=args.out_path)
interp_times = run_benchmarks(enable_yjit=false, name_filters=args.name_filters, out_path=args.out_path)
bench_end_time = Time.now.to_f
bench_names = yjit_times.keys.sort

bench_total_time = (bench_end_time - bench_start_time).to_i
puts("Total time spent benchmarking: #{bench_total_time}s")
puts()

# Table for the data we've gathered
table = [["bench", "interp (ms)", "stddev (%)", "yjit (ms)", "stddev (%)", "yjit/interp"]]

# Format the results table
bench_names.each do |bench_name|
    yjit_t = yjit_times[bench_name]
    interp_t = interp_times[bench_name]

    ratio = mean(yjit_t) / mean(interp_t)

    table.append([
        bench_name,
        mean(interp_t),
        100 * stddev(interp_t) / mean(interp_t),
        mean(yjit_t),
        100 * stddev(yjit_t) / mean(yjit_t),
        ratio
    ])
end

# Find a free file index for the output files
file_no = free_file_no(args.out_path)

# Save data as CSV so we can produce tables/graphs in a spreasheet program
# NOTE: we don't do any number formatting for the output file because
#       we don't want to lose any precision
output_tbl = [[ruby_version], []] + table
out_tbl_path = File.join(args.out_path, 'output_%03d.csv' % file_no)
CSV.open(out_tbl_path, "wb") do |csv|
    output_tbl.each do |row|
        csv << row
    end
end

# Save the output in a text file that we can easily refer to
output_str = ruby_version + "\n" + table_to_str(table) + "\n"
out_txt_path = File.join(args.out_path, "output_%03d.txt" % file_no)
File.open(out_txt_path, "w") { |f| f.write output_str }

# Save the raw data as JSON
out_json_path = File.join(args.out_path, "output_%03d.json" % file_no)
File.open(out_json_path, "w") do |file|
    data = {
        'yjit': yjit_times,
        'interp': interp_times,
        'ruby_version': ruby_version,
    }

    json_str = JSON.generate(data)
    file.write json_str
end

# Print the table to the console, with numbers truncated
puts(output_str)