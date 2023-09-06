# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# contributed by Jesse Millikan
# Modified by Wesley Moxam
# *reset*

def item_check(left, right)
  return 1 if left.nil?
  1 + item_check(*left) + item_check(*right)
end

def bottom_up_tree(depth)
  return [nil, nil] unless depth > 0
  depth -= 1
  [bottom_up_tree(depth), bottom_up_tree(depth)]
end

max_depth = 14
min_depth = 4

max_depth = min_depth + 2 if min_depth + 2 > max_depth
stretch_depth = max_depth + 1

require_relative '../../harness/setup'

run_benchmark(1) do
  stretch_tree = bottom_up_tree(stretch_depth)
  stretch_tree = nil

  long_lived_tree = bottom_up_tree(max_depth)

  min_depth.step(max_depth, 2) do |depth|
    iterations = 2**(max_depth - depth + min_depth)

    check = 0

    for i in 1..iterations
      temp_tree = bottom_up_tree(depth)
      check += item_check(*temp_tree)
    end
  end
end