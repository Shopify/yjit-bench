require_relative '../lib/rubykon'
require_relative 'support/benchmark-ips'
require_relative 'support/playout_help'

Benchmark.ips do |benchmark|
  game_9 = playout_for(9).game_state.game
  game_13 = playout_for(13).game_state.game
  game_19 = playout_for(19).game_state.game
  scorer = Rubykon::GameScorer.new

  benchmark.report '9x9 scoring' do
    scorer.score game_9
  end
  benchmark.report '13x13 scoring' do
    scorer.score game_13
  end
  benchmark.report '19x19 scoring' do
    scorer.score game_19
  end
end
