#!/usr/bin/env ruby

require 'etc'
require 'optparse'
require 'ostruct'
require 'pathname'
require 'fileutils'
require 'shellwords'
require 'csv'
require 'json'
require 'rbconfig'
require 'etc'
require 'yaml'
require 'open3'

def free_file_path(parent_dir, name_prefix)
  (1..).each do |file_no|
    out_path = File.join(parent_dir, "#{name_prefix}_%03d.txt" % file_no)
    if !File.exist?(out_path)
      return out_path
    end
  end
end

def run_benchmark(bench_name, logs_path, run_time, ruby_version)
  script_path = File.join('benchmarks', bench_name, 'benchmark.rb')

  env = {
    "WARMUP_ITRS"=> "0",
    "MIN_BENCH_TIME"=> run_time.to_s,
    "RUST_BACKTRACE"=> "1",
  }

  # Assemble random command-line options to test
  yjit_options = [
    "--yjit-call-threshold=#{[1, 2, 10, 30].sample()}",
    "--yjit-cold-threshold=#{[1, 2, 5, 10, 500, 50_000].sample()}",
    "--yjit-exec-mem-size=#{[1, 2, 3, 4, 5, 10, 64, 128].sample()}",
    ['--yjit-code-gc', nil].sample(),
    ['--yjit-perf', nil].sample(),
    ['--yjit-stats', nil].sample(),
  ].compact

  cmd = [
    'ruby',
    *yjit_options,
    "-Iharness",
    script_path,
  ].compact

  cmd_str = cmd.shelljoin

  puts "pid #{Process.pid} running benchmark #{bench_name}:"
  puts cmd_str

  output, status = Open3.capture2e(env, cmd_str)

  if !status.success?
    puts "ERROR"

    # Write command executed and output
    out_path = free_file_path(logs_path, "error_#{bench_name}")
    puts "writing output file #{out_path}"
    contents = ruby_version + "\n\n" + cmd_str + "\n\n" + output
    File.write(out_path, contents)

    return true
  end

  return false
end

def test_loop(bench_names, logs_path, run_time, ruby_version)
  error_found = false

  while true
    bench_name = bench_names.sample()
    error = run_benchmark(bench_name, logs_path, run_time, ruby_version)
    error_found ||= error

    if error_found
      puts "ERROR ENCOUNTERED"
    end
  end
end

# Default values for command-line arguments
args = OpenStruct.new({
  logs_path: "./logs_burn_in",
  num_procs: Etc.nprocessors,
  categories: ['headline', 'other'],
})

# Parse the command-line options
OptionParser.new do |opts|
  opts.on("--out_path=OUT_PATH", "directory where to store output data files") do |v|
    args.out_path = v
  end

  opts.on("--num_procs", "number of processes to use") do |v|
    args.categories = v.to_i
  end

  opts.on("--category=headline,other,micro", "when given, only benchmarks with specified categories will run") do |v|
    args.categories = v.split(",")
  end
end.parse!

# Create the output directory
if Dir.exist?(args.logs_path)
  puts("Logs directory already exists. Move or delete before running.")
  exit(-1)
end
FileUtils.mkdir_p(args.logs_path)

# Get Ruby version string
ruby_version = IO.popen("ruby -v --yjit", &:read).strip
puts ruby_version

# Check if debug info is included in Ruby binary (this only works on Linux, not macOS)
output = IO.popen("file `which ruby`", &:read).strip
if !output.include?("debug_info")
  puts("WARNING: could not detect debug info in ruby binary! You may want to rebuild in dev mode!")
  puts()
  sleep(10)
end

# Extract the names of benchmarks in the categories we want
metadata = YAML.load_file('benchmarks.yml')
metadata = metadata.filter do |bench_name, entry|
  category = entry.fetch('category', 'other')
  args.categories.include? category
end
bench_names = metadata.map { |name, entry| name }
bench_names.sort!

# Fork the test processes
puts "num processes: #{args.num_procs}"
args.num_procs.times do |i|
  pid = Process.fork do
    run_time = (i < args.num_procs / 2)? 10:(3600 * 2)
    test_loop(bench_names, args.logs_path, run_time, ruby_version)
  end
end

# We need some kind of busy loop to not exit?
# Loop and sleep, report if forked processes crashed?
while true
  sleep(50 * 0.001)
end
