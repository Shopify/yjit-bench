# Script to run a single benchmark once
# You can pass --yjit-stats and other ruby arguments to this script.
# eg:
# ./run_once.sh --yjit-stats benchmarks/railsbench/benchmark.rb

WARMUP_ITRS=0 MIN_BENCH_ITRS=1 MIN_BENCH_TIME=0 ruby -I./harness $*
