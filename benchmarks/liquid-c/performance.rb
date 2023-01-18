# frozen_string_literal: true

require "liquid"
require "liquid/c" if ARGV.shift == "c"
liquid_lib_dir = $LOAD_PATH.detect { |p| File.exist?(File.join(p, "liquid.rb")) }

(script = ARGV.shift) || abort("unspecified performance script")
require File.join(File.dirname(liquid_lib_dir), "performance/#{script}")
