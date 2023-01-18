# frozen_string_literal: true

at_exit { GC.start }

require_relative "liquid_test_helper"

test_files = Dir[File.join(LIQUID_TEST_DIR, "integration/**/*_test.rb")]
test_files << File.join(LIQUID_TEST_DIR, "unit/tokenizer_unit_test.rb")
test_files.each do |test_file|
  require test_file
end
