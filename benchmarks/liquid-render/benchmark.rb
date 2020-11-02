require 'harness'

#require 'benchmark/ips'
require_relative 'performance/theme_runner'

Liquid::Template.error_mode = ARGV.first.to_sym if ARGV.first
profiler = ThemeRunner.new

profiler.compile

run_benchmark(150) do
    # This benchmark is very quick
    # Run it multiple times to reduce time measurement noise
    20.times do
        profiler.render
    end
end
