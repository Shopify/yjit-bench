# frozen_string_literal: true

# Usage:
# MIN_BENCH_TIME=1 MIN_BENCH_ITRS=1 ruby -v -I harness-vernier benchmarks/...
# NO_VIEWER=1 MIN_BENCH_TIME=1 MIN_BENCH_ITRS=1 ruby -v -I harness-vernier benchmarks/...

require_relative "../harness/harness-common"
require_relative "../harness/harness-extra"

ensure_global_gem("vernier")
ensure_global_gem_exe("profile-viewer")

def run_benchmark(n, &block)
  require "vernier"

  out = output_file_path(ext: "json")
  Vernier.profile(out: out) do
    run_enough_to_profile(n, &block)
  end

  puts "Vernier profile:\n#{out}"
  gem_exe("profile-viewer", out) unless ENV['NO_VIEWER'] == '1'

  # Dummy results to satisfy ./run_benchmarks.rb
  return_results([0], [1.0])
end
