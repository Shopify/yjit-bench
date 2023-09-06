# This Rubykon runner is based on
# https://github.com/benchmark-driver/sky2-bench/blob/master/benchmark/rubykon-benchmark.rb,
# part of benchmark-driver's default benchmarking suite, by Takashi Kokubun.

require_relative '../../harness/loader'

require_relative 'lib/rubykon'

# Note: it's hard to validate correct behaviour because it's a Monte Carlo tree search. It doesn't
# return the same stable best_move, even for identical initial board state and number of iterations.

ITERATIONS = 1000
game_state_19 = Rubykon::GameState.new Rubykon::Game.new(19)
mcts = MCTS::MCTS.new

run_benchmark(10) do
  mcts.start game_state_19, ITERATIONS
end
