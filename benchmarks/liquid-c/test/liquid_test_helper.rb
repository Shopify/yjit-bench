# frozen_string_literal: true

# This can be used to setup for running tests from the liquid test suite.
# For example, you could run a single liquid test as follows:
# $ ruby -r./test/liquid_test_helper `bundle info liquid --path`/test/integration/template_test.rb

require "bundler/setup"

liquid_lib_dir = $LOAD_PATH.detect { |p| File.exist?(File.join(p, "liquid.rb")) }
LIQUID_TEST_DIR = File.join(File.dirname(liquid_lib_dir), "test")
$LOAD_PATH << LIQUID_TEST_DIR << File.expand_path("../lib", __dir__)

require "test_helper"
require "liquid/c"

if ENV["LIQUID_C_DISABLE_VM"]
  puts "-- Liquid-C VM Disabled"
  Liquid::ParseContext.liquid_c_nodes_disabled = true
end

GC.stress = true if ENV["GC_STRESS"]
