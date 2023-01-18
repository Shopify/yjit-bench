require 'harness'
# require "liquid"
# require "liquid/c"
Dir.chdir __dir__
use_gemfile

# $LOAD_PATH.unshift(__dir__ + '/lib')
# $LOAD_PATH.unshift(__dir__ + '/../liquid-render/lib')
# p $LOAD_PATH
require 'liquid/c'
liquid_lib_dir = $LOAD_PATH.detect { |p| File.exist?(File.join(p, "liquid.rb")) }
require File.join(File.dirname(liquid_lib_dir), "performance/theme_runner")

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
