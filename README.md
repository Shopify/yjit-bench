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

Install [chruby](https://github.com/postmodern/chruby)

Build MicroJIT:

```
sudo apt-get install sqlite3 libsqlite3-dev
git clone https://github.com/Shopify/ruby.git
cd ruby
git checkout microjit
./configure --prefix=$HOME/.rubies/ruby-microjit
make -j16 install
```

Install dependencies:
```
pip3 install --user tabulate
chruby ruby-microjit
gem install victor
```

See the [railsbench README](benchmarks/railsbench/README.md) for setting up `railsbench`.

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
ruby -I./harness benchmarks/fib.rb

# For macro-benchmarks, there is a benchmark.rb file in each directory:
ruby -I./harness benchmarks/lee/benchmark.rb
```

To run one individual benchmark and record the data:
```
./run_benchmarks.py $BENCHMARK_NAME
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
