# a simple script doing a full playout to use it with profiling tools
# ruby-prof -p call_stack benchmark/profiling/full_playout.rb -f profiling_playout.html

require_relative '../../lib/rubykon/'
require_relative '../support/playout_help'

playout_for 19
