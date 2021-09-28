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
chruby ruby-yjit
gem install victor
```

## Usage

To run all the benchmarks and record the data:
```
cd yjit-bench
chruby ruby-yjit
./run_benchmarks.rb
```

This runs for a few minutes and produces a table like this in the console (results below not up to date):
```
-------------  -----------  ----------  ---------  ----------  -----------  ------------
bench          interp (ms)  stddev (%)  yjit (ms)  stddev (%)  interp/yjit  yjit 1st itr
30k_ifelse     2372.0       0.0         447.6      0.1         5.30         4.16        
30k_methods    6328.3       0.0         963.4      0.0         6.57         6.25        
activerecord   171.7        0.8         144.2      0.7         1.19         1.15        
binarytrees    445.8        2.1         389.5      2.5         1.14         1.14        
cfunc_itself   105.7        0.2         58.7       0.7         1.80         1.80        
fannkuchredux  6697.3       0.1         6714.4     0.1         1.00         1.00        
fib            245.3        0.1         77.1       0.4         3.18         3.19        
getivar        97.3         0.9         44.3       0.6         2.19         0.98        
lee            1269.7       0.9         1172.9     1.0         1.08         1.08        
liquid-render  204.5        1.0         172.4      1.3         1.19         1.18        
nbody          121.9        0.1         121.6      0.3         1.00         1.00        
optcarrot      6260.2       0.5         4723.1     0.3         1.33         1.33        
railsbench     3827.9       0.9         3581.3     1.3         1.07         1.05        
respond_to     259.0        0.6         197.1      0.4         1.31         1.31        
setivar        73.1         0.2         53.3       0.7         1.37         1.00        
-------------  -----------  ----------  ---------  ----------  -----------  ------------
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

There is also a harness to run benchmarks for a fixed
number of iterations, for example to use with the `perf stat` tool:

```
ruby --yjit-stats -I./harness-perf benchmarks/lee/benchmark.rb
```

And finally, there is a handy script for running benchmarks just
once, for example with the `--yjit-stats` command-line option:

```
./run_once.sh --yjit --yjit-stats benchmarks/railsbench/benchmark.rb
```

For YJIT, you may need to pass an appropriate parameter to enable JIT.

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
