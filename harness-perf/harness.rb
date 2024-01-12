require_relative "../harness/harness-common"

# This harness is meant for use with perf stat
# All it does is run the benchmark a number of times

# Takes a block as input
def run_benchmark(num_itrs_hint)
  warmup_itrs = Integer(ENV.fetch('WARMUP_ITRS', 10))
  bench_itrs = Integer(ENV.fetch('MIN_BENCH_ITRS', num_itrs_hint))

  # Run warmup
  i = 0
  while i < warmup_itrs
    yield
    i += 1
  end

  # Start perf after warmup
  if ENV['PERF']
    pid = Process.spawn(
      'perf', *ENV['PERF'].split(' '), '-p', Process.pid.to_s,
      '-o', File.expand_path('../perf.data', __dir__), # ignore Dir.chdir
    )
  end

  # Run benchmark
  i = 0
  while i < bench_itrs
    yield
    i += 1
  end
ensure
  if pid
    Process.kill(:INT, pid)
    Process.wait(pid)
  end
end
