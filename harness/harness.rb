require 'benchmark'
require_relative "./harness-common"
require 'stackprof'

# Warmup iterations
WARMUP_ITRS = Integer(ENV.fetch('WARMUP_ITRS', 15))

# Minimum number of benchmarking iterations
MIN_BENCH_ITRS = Integer(ENV.fetch('MIN_BENCH_ITRS', 10))

# Minimum benchmarking time in seconds
MIN_BENCH_TIME = Integer(ENV.fetch('MIN_BENCH_TIME', 10))

default_path = "data/results-#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}-#{Time.now.strftime('%F-%H%M%S')}.csv"
OUT_CSV_PATH = File.expand_path(ENV.fetch('OUT_CSV_PATH', default_path))

RSS_CSV_PATH = ENV['RSS_CSV_PATH'] ? File.expand_path(ENV['RSS_CSV_PATH']) : nil

system('mkdir', '-p', File.dirname(OUT_CSV_PATH))

puts RUBY_DESCRIPTION

# Takes a block as input
def run_benchmark(_num_itrs_hint)
  times = []
  total_time = 0
  num_itrs = 0

  begin
    time = Benchmark.realtime { yield }
    num_itrs += 1

    # NOTE: we may want to avoid this as it could trigger GC?
    time_ms = (1000 * time).to_i
    puts "itr \##{num_itrs}: #{time_ms}ms"

    # NOTE: we may want to preallocate an array and avoid append
    # We internally save the time in seconds to avoid loss of precision
    times << time
    total_time += time

    if num_itrs == WARMUP_ITRS
      puts "Starting profiling"
      StackProf.start(mode: :wall, raw: true)
    end
  end until num_itrs >= WARMUP_ITRS + MIN_BENCH_ITRS and total_time >= MIN_BENCH_TIME

  StackProf.stop
  StackProf.results('/tmp/lobsters-wall.marshal')

  warmup, bench = times[0...WARMUP_ITRS], times[WARMUP_ITRS..-1]
  return_results(warmup, bench)

  non_warmups = times[WARMUP_ITRS..-1]
  if non_warmups.size > 1
    non_warmups_ms = ((non_warmups.sum / non_warmups.size) * 1000.0).to_i
    puts "Average of last #{non_warmups.size}, non-warmup iters: #{non_warmups_ms}ms"
  end
end
