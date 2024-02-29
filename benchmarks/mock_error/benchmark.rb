# frozen_string_literal: true

require_relative '../../harness/loader'

s = "string"
run_benchmark(1) do
  s.some_hopefully_unknown_method
end
