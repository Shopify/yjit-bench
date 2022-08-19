require_relative "../harness/harness-common"

# This harness is meant for use with perf stat
# All it does is run the benchmark a number of times

# Takes a block as input
def run_benchmark(num_itrs_hint)
  i = 0
  while i < num_itrs_hint
    yield
    i += 1
  end
end
