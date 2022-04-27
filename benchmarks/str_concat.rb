# frozen_string_literal: true
require 'harness'

# Structuring this with a single method means we will not
# get a single-encoding call site. That doesn't matter now,
# but may matter with more-optimised generated code.
def concat_single_test(n, encoding, str_to_add)
  # We used to supply capacity when building a string, but so far
  # it makes only a very small difference - around 5.08 vs 5.09 sec
  # for 10k iterations. Maybe add it back when/if we've optimised
  # significantly more?
  s = String.new(encoding: encoding)
  i = 0
  while i < n
    s << str_to_add
    i += 1
  end

  s
end

def concat_test
  # So far, binary versus UTF-8 encoding makes effectively no
  # difference in speed here. Observed diff is around 69.5 vs 68.9
  # iters/sec.
  concat_single_test(10 * 1024, Encoding::UTF_8, 'sssssséé')
  concat_single_test(10 * 1024, Encoding::BINARY, 'sssssséé')
end

run_benchmark(100) do
  100.times { concat_test }
end
