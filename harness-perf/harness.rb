require_relative "../harness/harness-common"

# This harness is meant for use with perf stat
# All it does is run the benchmark a number of times

# Takes a block as input. "values" is a special name-value that names the results after this benchmark.
def run_benchmark(num_itrs_hint, benchmark_name: "ignored", &block)
  calculate_benchmark(num_itrs_hint, &block)
end

# For the perf harness, just run this number of times
def calculate_benchmark(num_itrs_hint, benchmark_name: "ignored")
  i = 0
  while i < num_itrs_hint
    yield
    i += 1
  end
end
