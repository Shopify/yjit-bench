require 'harness'

#require 'benchmark/ips'
require_relative 'performance/theme_runner'

Liquid::Template.error_mode = ARGV.first.to_sym if ARGV.first
profiler = ThemeRunner.new

profiler.compile

run_benchmark(1500) do
    profiler.render
end
