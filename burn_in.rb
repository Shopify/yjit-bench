#!/usr/bin/env ruby

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

# Checked system - error if the command fails
def check_call(command, verbose: false, env: {})
  puts(command)

  if verbose
    status = system(env, command, out: $stdout, err: :out)
  else
    status = system(env, command)
  end

  unless status
    puts "Command #{command.inspect} failed in directory #{Dir.pwd}"
    raise RuntimeError.new
  end
end

def check_output(*command)
  IO.popen(*command, &:read)
end

def free_file_no(prefix)
  (1..).each do |file_no|
    out_path = File.join(prefix, "output_%03d.csv" % file_no)
    if !File.exist?(out_path)
      return file_no
    end
  end
end

# Default values for command-line arguments
args = OpenStruct.new({
  out_path: "./burn_in_logs",
  num_procs: 32,
  categories: ['headline', 'other'],
})

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

puts "num processes: #{args.num_procs}"
#puts args.categories

metadata = YAML.load_file('benchmarks.yml')

# Extract the names of benchmarks in the categories we want
metadata = metadata.filter do |bench_name, entry|
  category = entry.fetch('category', 'other')
  args.categories.include? category
end
bench_names = metadata.map { |name, entry| name }
bench_names.sort!

puts bench_names

# Create the output directory
FileUtils.mkdir_p(args.out_path)








