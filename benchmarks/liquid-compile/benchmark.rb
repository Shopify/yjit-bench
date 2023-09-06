require_relative '../../harness/loader'

Dir.chdir __dir__
use_gemfile

require 'liquid'
liquid_lib_dir = $LOAD_PATH.detect { |p| File.exist?(File.join(p, "liquid.rb")) }
require File.join(File.dirname(liquid_lib_dir), "performance/theme_runner")

run_benchmark(150) do
  profiler = ThemeRunner.new
  profiler.compile
end
