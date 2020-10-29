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

Building MicroJIT:

```
git clone https://github.com/Shopify/ruby.git
git checkout microjit
./configure --prefix=$HOME/.rubies/ruby-microjit
make -j16 install
```

Installing dependencies:
```
pip3 install --user tabulate
gem install victor
```

## Usage

To run all the benchmarks and record the data:
```
chruby ruby-microjit
./run_benchmarks.py
```

This runs for a few minutes and produces a table like this in the console:
```
-------------  -----------  ----------  ---------  ----------  -----------
bench          interp (ms)  stddev (%)  ujit (ms)  stddev (%)  speedup (%)
cfunc_itself   254.3        1.7         201.5      3.6         20.8
fib            169.8        1.3         138.5      1.4         18.4
getivar        87.5         1.4         66.4       3.3         24.1
lee            1153.2       2.2         1099.1     1.7         4.7
liquid-render  10.0         10.7        9.9        7.5         1.0
optcarrot      4530.5       1.8         4625.7     0.7         -2.1
setivar        92.5         2.4         68.9       2.0         25.5
-------------  -----------  ----------  ---------  ----------  -----------
```

To run one individual benchmark without recording the data:
```
# For single-file microbenchmarks:
ruby -I./lib benchmarks/fib.rb

# For macro-benchmarks, there is a benchmark.rb file in each directory:
ruby -I./lib benchmarks/lee/benchmark.rb
```
