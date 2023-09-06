# Use harness/harness.rb by default. You can change it with -I option.
# i.e. ruby -Iharness benchmarks/railsbench/benchmark.rb
$LOAD_PATH << File.expand_path(__dir__)
require "harness"
