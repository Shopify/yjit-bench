yjit-bench
==========

Small set of benchmarks and scripts for the YJIT Ruby JIT compiler project, which lives in
the [Shopify/yjit](https://github.com/Shopify/yjit) repository.

The benchmarks are found in the `benchmarks` directory. Individual Ruby files
in `benchmarks` are microbenchmarks. Subdirectories under `benchmarks` are
larger macrobenchmarks. Each benchmark relies on a harness found in
`/lib/harness.rb`. The harness controls the number of times a benchmark is
run, and writes timing values into an output CSV file.

The `run_benchmarks.rb` script pulls the latest commits from the YJIT repo,
recompiles the YJIT ruby installation,
and then traverses the `benchmarks` directory and
to automatically discover and run the benchmarks in there. It reads the
CSV file written by the benchmarking harness. The output is written to
an output CSV file at the end, so that results can be easily viewed or
graphed in any spreadsheet editor.

## Installation

Install [chruby](https://github.com/postmodern/chruby)

Clone this repository:
```
git clone https://github.com/Shopify/yjit-bench.git yjit-bench
```

Build YJIT:

```
sudo apt-get install sqlite3 libsqlite3-dev
git clone https://github.com/Shopify/yjit.git yjit
cd yjit
./autogen.sh
./configure --disable-install-doc --disable--install-rdoc --prefix=$HOME/.rubies/ruby-yjit
make -j16 install
```

Install dependencies:
```
pip3 install --user tabulate
chruby ruby-yjit
gem install victor
```

See the [railsbench README](benchmarks/railsbench/README.md) for setting up `railsbench`.

## Usage

To run all the benchmarks and record the data:
```
cd yjit-bench
chruby ruby-yjit
./run_benchmarks.rb
```

This runs for a few minutes and produces a table like this in the console:
```
-------------  -----------  ----------  ---------  ----------  -----------  -------
bench          interp (ms)  stddev (%)  yjit (ms)  stddev (%)  interp/yjit  1st itr
30k_ifelse     2322.8       0.0         399.7      0.0         5.81         4.48
30k_methods    6502.7       0.0         900.9      0.0         7.22         6.85
binarytrees    440.1        2.0         387.3      2.1         1.14         1.14
cfunc_itself   108.8        0.4         58.9       0.6         1.85         1.84
fannkuchredux  4839.4       0.0         4786.5     0.1         1.01         1.01
fib            240.9        0.1         76.3       0.1         3.16         3.16
getivar        118.6        0.1         49.9       0.1         2.38         1.02
lee            1300.4       0.6         1231.1     0.7         1.06         1.07
liquid-render  204.9        3.3         187.3      1.1         1.09         1.08
nbody          132.6        0.1         131.8      0.1         1.01         1.00
optcarrot      6268.4       0.3         5493.2     0.2         1.14         1.13
railsbench     3957.1       1.1         3989.5     0.9         0.99         0.97
setivar        70.8         0.1         27.3       0.1         2.59         1.01
-------------  -----------  ----------  ---------  ----------  -----------  -------
```

The `interp/yjit` column is the ratio of the average time taken by the interpreter over the
average time taken by YJIT after a number of warmup iterations. Results above 1 represent
speedups. For instance, 1.14 means "YJIT is 1.14 times as fast as the interpreter".

To run one or more specific benchmarks and record the data:
```
./run_benchmarks.rb fib lee optcarrot
```

To benchmark YJIT with specific command-line options on specific benchmarks:
```
./run_benchmarks.rb --yjit_opts="--yjit-version-limit=10" fib lee optcarrot
```

To run one individual benchmark without recording the data:
```
# For single-file microbenchmarks:
ruby -I./harness benchmarks/fib.rb

# For macro-benchmarks, there is a benchmark.rb file in each directory:
ruby -I./harness benchmarks/lee/benchmark.rb
```

There is also a harness that is designed to run benchmarks for a fixed
number of iterations, for example to use with the `perf stat` tool or
with the `--yjit-stats` command-line option:

```
ruby --yjit-stats -I./harness-perf benchmarks/lee/benchmark.rb
```

## Disabling CPU Frequency Scaling

To disable CPU frequency scaling on your AWS instance, edit `/etc/default/grub.d/50-cloudimg-settings.cfg` and add `intel_pstate=no_hwp` to `GRUB_CMDLINE_LINUX_DEFAULT`. It’s a space-separated list.

Then:
```
sudo update-grub
 - sudo reboot
 - sudo sh -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'
```

To verify things worked:
 - `cat /proc/cmdline` to see the `intel_pstate=no_hwp` parameter is in there
 - `ls /sys/devices/system/cpu/intel_pstate/` and `hwp_dynamic_boost` should not exist
 - `cat /sys/devices/system/cpu/intel_pstate/no_turbo` should say `1`

Helpful docs:
 - https://01.org/linuxgraphics/gfx-docs/drm/admin-guide/pm/intel_pstate.html
 - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/processor_state_control.html#baseline-perf
