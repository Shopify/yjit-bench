yjit-bench
==========

Small set of benchmarks and scripts for the YJIT Ruby JIT compiler project, which lives in
the [Shopify/yjit](https://github.com/Shopify/yjit) repository.

The benchmarks are found in the `benchmarks` directory. Individual Ruby files
in `benchmarks` are microbenchmarks. Subdirectories under `benchmarks` are
larger macrobenchmarks. Each benchmark relies on a harness found in
`/lib/harness.rb`. The harness controls the number of times a benchmark is
run, and writes timing values into an output CSV file.

The `run_benchmarks.rb` script traverses the `benchmarks` directory and
runs the benchmarks in there. It reads the
CSV file written by the benchmarking harness. The output is written to
an output CSV file at the end, so that results can be easily viewed or
graphed in any spreadsheet editor.

yjit-bench expects to use chruby to run with YJIT.

## Installation

Install [chruby](https://github.com/postmodern/chruby)

Clone this repository:
```
git clone https://github.com/Shopify/yjit-bench.git yjit-bench
```

Follow [these instructions](https://github.com/ruby/ruby/blob/master/doc/yjit/yjit.md#building-yjit) to build and install YJIT with the name ruby-yjit.

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

### Specific benchmarks

To run one or more specific benchmarks and record the data:
```
./run_benchmarks.rb fib lee optcarrot
```

### YJIT options

To benchmark YJIT with specific command-line options on specific benchmarks:
```
./run_benchmarks.rb --yjit_opts="--yjit-version-limit=10" fib lee optcarrot
```

### Ruby commands

By default, yjit-bench compares two Ruby commands, `-e "interp::ruby"` and
`-e "yjit::ruby --yjit $yjit_opts"`, with the Ruby used for `run_benchmarks.rb`.
However, if you specify `-e` yourself, you can override what Ruby is benchmarked.

```sh
# "xxx::" prefix can be used to specify a shorter name/alias, but it's optional.
./run_benchmarks.rb -e "mjit::ruby --mjit" -e "truffleruby"
```

You could also measure only a single Ruby.

```
./run_benchmarks.rb -e "ruby"
```


### Running pre-init code

Occasionally it may be necessary to run code for each benchmark, but
before the benchmark starts. This can be done with the
`--with-pre-init` option.

For example: to run benchmarks with `GC.auto_compact` enabled, create
a `pre-init.rb` file containing `GC.auto_compact=true` and then run
the benchmarks, passing the path to the pre-init file:

```
./run_benchmarks.rb --with-pre-init=./pre-init.rb
```

### Using perf

There is also a harness to run benchmarks for a fixed
number of iterations, for example to use with the `perf stat` tool:

```
ruby --yjit-stats -I./harness-perf benchmarks/lee/benchmark.rb
```

### Harnesses

And finally, there is a handy script for running benchmarks just
once, for example with the `--yjit-stats` command-line option:

```
./run_once.sh --yjit-stats benchmarks/railsbench/benchmark.rb
```

You can find several test harnesses in this repository:

* harness - the normal default harness, with duration controlled by warmup iterations and time/count limits
* harness-perf - a simplified harness that runs for exactly the hinted number of iterations
* harness-bips - a harness that measures iterations/second until stable
* harness-continuous - a harness that adjusts the batch sizes of iterations to run in stable iteration size batches

There is also a robust but complex CI harness in [the yjit-metrics repo](https://github.com/Shopify/yjit-metrics).

## Disabling CPU Frequency Scaling

To disable CPU frequency scaling on an AWS instance with an Intel CPU, edit `/etc/default/grub.d/50-cloudimg-settings.cfg` and add `intel_pstate=no_hwp` to `GRUB_CMDLINE_LINUX_DEFAULT`. It’s a space-separated list.

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
