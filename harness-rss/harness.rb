# frozen_string_literal: true
# Runs the benchmark for 5 minutes, colleting RSS after each iteration

require_relative '../harness/harness-common'
require 'benchmark'

def run_benchmark(_hint)
  now = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC, :second) }

  times = []
  rss_over_time = []
  goal_time = now.() + 5 * 60

  begin
    times << Benchmark.realtime { yield }
    rss_over_time << get_rss
    STDOUT.printf("iter %03d: %5dms %dMiB\n",
                  times.size, times.last*1000, rss_over_time.last/2**20)
  end until now.() > goal_time

  # HACK: put per iteration RSS info under "warmup" key in the output JSON
  return_results(rss_over_time, times) # bogus timing
end
