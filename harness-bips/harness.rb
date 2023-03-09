require 'benchmark/ips'
require_relative "../harness/harness-common"

puts RUBY_DESCRIPTION

def calculate_benchmark(_, benchmark_name: "values", &block)
  puts "Calculated benchmark values are not supported by the benchmark-ips harness!"
end

def run_benchmark(_, benchmark_name: "values", &block)
  Benchmark.ips do |x|
    x.report 'benchmark', &block
  end
end
