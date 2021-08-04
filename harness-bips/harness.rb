require 'benchmark/ips'

puts RUBY_DESCRIPTION

def run_benchmark(_, &block)
  Benchmark.ips do |x|
    x.report 'benchmark', &block
  end
end
