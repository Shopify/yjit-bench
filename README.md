microjit-bench
==============

Small set of benchmarks and scripts for the MicroJIT project.

The benchmarks are found in the `benchmarks` directory. Individual Ruby files
in `benchmarks` are microbenchmarks. Subdirectories under `benchmarks` are
larger macrobenchmarks.

Each benchmark includes a harness found in `/lib/harness.rb`. The harness
controls the number of times a benchmark is run, and writes timing values
into an output CSV file.

The `run_benchmarks.py` script traverses the `benchmarks` directory and
automatically discovers and runs the benchmarks in there. It reads the
CSV file written by the benchmarking harness. The output is written to
an output CSV file at the end, so that results can be easily viewed or
graphed in any spreadsheet editor.

## Installation

```
pip3 install --user tabulate
gem install victor
```

## Usage

Running all the benchmarks:
```
chruby ruby-microjit
./run_benchmarks.py
```

Running one individual benchmark:
```
# For single-file microbenchmarks:
ruby -I./lib benchmarks/fib.rb

# For macro-benchmarks, there is a benchmark.rb file in each directory:
ruby -I./lib benchmarks/lee/benchmark.rb
```
