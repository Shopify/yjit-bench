require 'csv'

# Warmup iterations
$WARMUP_ITRS = ENV.fetch('WARMUP_ITRS', 15).to_i

# Minimum number of benchmarking iterations
$MIN_BENCH_ITRS = 10

# Minimum benchmarking time in seconds
$MIN_BENCH_TIME = 10

$out_csv_path = ENV.fetch('OUT_CSV_PATH', 'output.csv')

# Time one iteration of a benchmark
def time_itr
    start_time = Time.now.to_f
    yield
    end_time = Time.now.to_f
    delta_time = end_time - start_time
    return delta_time
end

# Takes a block as input
def run_benchmark(num_itrs_hint)
    times = []
    total_time = 0

    num_itrs = 0
    loop do
        time = time_itr { yield }
        num_itrs += 1

        # NOTE: we may want to avoid this as it could trigger GC?
        time_ms = (1000 * time).to_i
        puts "itr \##{num_itrs}: #{time_ms}ms"

        # NOTE: we may want to preallocate an array and avoid append
        # We internally save the time in seconds to avoid loss of precision
        times << time
        total_time += time

        if num_itrs >= $WARMUP_ITRS + $MIN_BENCH_ITRS and total_time >= $MIN_BENCH_TIME
            break
        end
    end

    # Write each time value on its own row
    CSV.open($out_csv_path, "wb") do |csv|
        csv << times
    end
end
