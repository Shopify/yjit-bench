# ruby-prof -p call_stack benchmark/profiling/mcts.rb -f profiling_mcts.html

require_relative '../../lib/rubykon'

game_state = Rubykon::GameState.new
mcts = MCTS::MCTS.new

mcts.start game_state, 200
