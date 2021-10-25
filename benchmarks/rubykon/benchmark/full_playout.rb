require_relative '../lib/rubykon'
require_relative 'support/playout_help'
require_relative 'support/benchmark-ips'

Benchmark.ips do |benchmark|
  benchmark.config time: 180, warmup: 120

  benchmark.report '19x19 full playout (+ score)' do
    full_playout_for 19
  end
end
