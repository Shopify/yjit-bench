require 'benchmark'
require_relative "./harness-common"

# Warmup iterations
WARMUP_ITRS = ENV.fetch('WARMUP_ITRS', 15).to_i

# Minimum number of benchmarking iterations
MIN_BENCH_ITRS = ENV.fetch('MIN_BENCH_ITRS', 10).to_i

# Minimum benchmarking time in seconds
MIN_BENCH_TIME = ENV.fetch('MIN_BENCH_TIME', 10).to_i

puts RUBY_DESCRIPTION

# Takes a block as input. "values" is a special name-value that names the results after this benchmark.
def run_benchmark(num_itrs_hint, benchmark_name: "values", &block)
  calculate_benchmark(num_itrs_hint, benchmark_name:benchmark_name) { Benchmark.realtime { yield } }
end

# For calculate_benchmark, the block calculates a time value in fractional seconds and returns it.
# This permits benchmarks that add or subtract multiple times, or import times from a different
# runner.
def calculate_benchmark(_num_itrs_hint, benchmark_name: "values")
  times = []
  total_time = 0
  num_itrs = 0

  begin
    time = yield
    num_itrs += 1

    # NOTE: we may want to avoid this as it could trigger GC?
    time_ms = (1000 * time).to_i
    puts "itr \##{num_itrs}: #{time_ms}ms"

    # NOTE: we may want to preallocate an array and avoid append
    # We internally save the time in seconds to avoid loss of precision
    times << time
    total_time += time
  end until num_itrs >= WARMUP_ITRS + MIN_BENCH_ITRS and total_time >= MIN_BENCH_TIME

  # Collect our own peak mem usage as soon as reasonable after finishing the last iteration.
  peak_mem_bytes = get_rss
  return_results("#{benchmark_name}:rss", peak_mem_bytes)
  puts "RSS: %.1fMiB" % (peak_mem_bytes / 1024.0 / 1024.0)

  return_results(benchmark_name, times)

  non_warmups = times[WARMUP_ITRS..-1]
  if non_warmups.size > 1
    non_warmups_ms = ((non_warmups.sum / non_warmups.size) * 1000.0).to_i
    puts "Average of last #{non_warmups.size}, non-warmup iters: #{non_warmups_ms}ms"
  end
end
