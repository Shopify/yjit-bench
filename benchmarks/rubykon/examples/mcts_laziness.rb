require_relative '../lib/mcts'
require_relative '../lib/mcts/examples/double_step'

mcts = MCTS::MCTS.new


[
 {black: -4, white: 0}, {black: -3, white: 0}, {black: -2, white: 0},
 {black: -1, white: 0}, {black: 0, white: 0}, {black: 0, white: -1},
 {black: 0, white: -2}, {black: 0, white: -3},
 {black: 0, white: -4}].each do |position|
  [2, 4, 8, 10, 16, 32, 64, 100].each do |playouts|
    results = Hash.new {0}
    double_step_game = MCTS::Examples::DoubleStep.new position[:black], position[:white]
    10_000.times do |i|
      root = mcts.start double_step_game, playouts
      best_move = root.best_move
      results[best_move] += 1
    end
    puts "Distribution for #{playouts} playouts with a handicap of #{position[:black] - position[:white]}: #{results}"
  end
end
