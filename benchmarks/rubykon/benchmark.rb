# This Rubykon runner is based on
# https://github.com/benchmark-driver/sky2-bench/blob/master/benchmark/rubykon-benchmark.rb,
# part of benchmark-driver's default benchmarking suite, by Takashi Kokubun.

require 'harness'

# Before we activate Bundler, make sure gems are installed.
Dir.chdir(__dir__) do
  chruby_stanza = ""
  if ENV['RUBY_ROOT']
    ruby_name = ENV['RUBY_ROOT'].split("/")[-1]
    chruby_stanza = "chruby && chruby #{ruby_name} && "
  end

  # Source Shopify-located chruby if it exists to make sure this works in Shopify Mac dev tools.
  # Use bash -l to propagate non-Shopify-style chruby config.
  success = system("/bin/bash -l -c '[ -f /opt/dev/dev.sh ] && . /opt/dev/dev.sh; #{chruby_stanza}bundle install'")
  unless success
    raise "Couldn't set up benchmark!"
  end
end

require_relative 'lib/rubykon'

# Note: it's hard to validate correct behaviour because it's a Monte Carlo tree search. It doesn't
# return the same stable best_move, even for identical initial board state and number of iterations.

ITERATIONS = 1000
game_state_19 = Rubykon::GameState.new Rubykon::Game.new(19)
mcts = MCTS::MCTS.new

run_benchmark(10) do
    mcts.start game_state_19, ITERATIONS
end
