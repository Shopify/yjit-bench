require 'benchmark'
require_relative "./harness-common"

# Warmup iterations
WARMUP_ITRS = ENV.fetch('WARMUP_ITRS', 15).to_i

# Minimum number of benchmarking iterations
MIN_BENCH_ITRS = ENV.fetch('MIN_BENCH_ITRS', 10).to_i

# Minimum benchmarking time in seconds
MIN_BENCH_TIME = ENV.fetch('MIN_BENCH_TIME', 10).to_i

default_path = "data/results-#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}-#{Time.now.strftime('%F-%H%M%S')}.csv"
OUT_CSV_PATH = File.expand_path(ENV.fetch('OUT_CSV_PATH', default_path))

system('mkdir', '-p', File.dirname(OUT_CSV_PATH))

puts RUBY_DESCRIPTION

# Takes a block as input
def run_benchmark(num_itrs_hint)
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
  end until num_itrs >= WARMUP_ITRS + MIN_BENCH_ITRS and total_time >= MIN_BENCH_TIME

  # Write each time value on its own line
  File.write(OUT_CSV_PATH, "#{RUBY_DESCRIPTION}\n#{times.join("\n")}\n")

  non_warmups = times[WARMUP_ITRS..-1]
  if non_warmups.size > 1
    non_warmups_ms = ((non_warmups.sum / non_warmups.size) * 1000.0).to_i
    puts "Average of last #{non_warmups.size}, non-warmup iters: #{non_warmups_ms}ms"
  end
end
