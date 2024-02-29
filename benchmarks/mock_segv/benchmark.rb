# frozen_string_literal: true

require_relative '../../harness/loader'

Dir.chdir(__dir__)
use_gemfile

require 'ffi'

run_benchmark(1) do
  FFI::Pointer.new(42).read_int
end
