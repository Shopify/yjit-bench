# frozen_string_literal: true

require_relative "../../harness/loader"

Dir.chdir(__dir__)
use_gemfile

# Rubyboy has a Bench module which is just a loop around `emulator.step`.
# https://github.com/sacckey/rubyboy/blob/e6c7d1d64ed7c6edb0ec6bae25ae3e7ec4cc9319/lib/bench.rb

require 'rubyboy/emulator_headless'

# The rom is included in the gem in a sibling directory to the rubyboy code.
rom_path = File.expand_path("../../roms/tobu.gb", $".detect { |x| x.end_with?("/rubyboy/emulator_headless.rb") })

# A count of 500 produces results similar to our optcarrot benchmark.
# It's possible there is a number that produces a consistent benchmark without
# needing to re-initialize but not sure how to determine that.
count = 500

run_benchmark(200) do
  # Results are much more consistent if we re-initialize each time.
  # Reusing the same eumlator increases stddev by 65x.
  emulator = Rubyboy::EmulatorHeadless.new(rom_path)
  count.times do
    emulator.step
  end
end
