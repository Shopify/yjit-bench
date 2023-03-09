require "harness"
require "benchmark"

# Change to the benchmarks directory
Dir.chdir __dir__

# Run one iteration of each of these
env_hash = {
  "WARMUP_ITRS" => "0",
  "MIN_BENCH_TIME" => "0",
  "MIN_BENCH_ITRS" => "1",
  "30K_INTERNAL_ITRS" => "1", # If we do 600+ iters, the compile time appears *negative*
  "RESULT_JSON_PATH" => "/tmp/throwaway.json",
}

cmd_prefix = ["ruby", "-I../harness"]

# Note: these benchmarks don't need gems installed - bundler overhead adds a lot of noise
[ "30k_ifelse", "30k_methods" ].each do |bench_name|
  yjit_cmd = cmd_prefix + ["--yjit-call-threshold=1", "#{bench_name}.rb"]
  interp_cmd = cmd_prefix + ["--disable-jit", "#{bench_name}.rb"]
  calculate_benchmark(10, benchmark_name: "#{bench_name}_compile_time") do
    t_compile = Benchmark.realtime { run_cmd(env_hash, *yjit_cmd) }
    t_interp = Benchmark.realtime { run_cmd(env_hash, *interp_cmd) }

    if t_interp > t_compile
      # Weird. We assumed compilation would be slow enough that *one* iteration would always be slower.
      raise "Benchmark assumptions violated!"
    end

    t_compile - t_interp
  end
end
