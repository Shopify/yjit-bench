## 0.3 More Reliable playouts + new benchmarking

Benchmarking is anew, with the help of the truffle/graal team a shim for benchmark/ips is in use that doesn't confuse the JIT as much yielding nice results.

Moreover, a second more macro benchmark is in use that runs a whole actual MCTS with a predefined number of playouts. This is benchmarked using benchmark/avg I wrote to be more suitable for more macro benchmarks. Also it doesn't do anything inbetween warmup and measuring, so it is not confusing truffle as much.

### Playouts + Scoring


```
Running 1.9.3 with
Using /home/tobi/.rvm/gems/ruby-1.9.3-p551
ruby 1.9.3p551 (2014-11-13 revision 48407) [x86_64-linux]
Calculating -------------------------------------
9x9 full playout (+ score)
                        24.000  i/100ms
13x13 full playout (+ score)
                        10.000  i/100ms
19x19 full playout (+ score)
                         4.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        252.308  (± 4.8%) i/s -      7.560k
13x13 full playout (+ score)
                        107.774  (±11.1%) i/s -      3.190k
19x19 full playout (+ score)
                         44.952  (± 8.9%) i/s -      1.344k


Running jruby with
Using /home/tobi/.rvm/gems/jruby-9.0.3.0
jruby 9.0.3.0 (2.2.2) 2015-10-21 633c9aa OpenJDK 64-Bit Server VM 25.45-b02 on 1.8.0_45-internal-b14 +jit [linux-amd64]
Calculating -------------------------------------
9x9 full playout (+ score)
                        38.000  i/100ms
13x13 full playout (+ score)
                        17.000  i/100ms
19x19 full playout (+ score)
                         7.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        405.833  (± 4.9%) i/s -     12.160k
13x13 full playout (+ score)
                        181.332  (± 5.5%) i/s -      5.423k
19x19 full playout (+ score)
                         73.479  (± 6.8%) i/s -      2.198k


Running rbx-2.5.8 with
Using /home/tobi/.rvm/gems/rbx-2.5.8
rubinius 2.5.8 (2.1.0 bef51ae3 2015-11-08 3.4.2 JI) [x86_64-linux-gnu]
Calculating -------------------------------------
9x9 full playout (+ score)
                        18.000  i/100ms
13x13 full playout (+ score)
                         9.000  i/100ms
19x19 full playout (+ score)
                         4.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        199.825  (± 4.0%) i/s -      5.994k
13x13 full playout (+ score)
                         92.732  (± 4.3%) i/s -      2.781k
19x19 full playout (+ score)
                         40.911  (± 4.9%) i/s -      1.224k


Running jruby-9 with --server -Xcompile.invokedynamic=true -J-Xmx1500m
Using /home/tobi/.rvm/gems/jruby-9.0.3.0
jruby 9.0.3.0 (2.2.2) 2015-10-21 633c9aa OpenJDK 64-Bit Server VM 25.45-b02 on 1.8.0_45-internal-b14 +jit [linux-amd64]
Calculating -------------------------------------
9x9 full playout (+ score)
                        66.000  i/100ms
13x13 full playout (+ score)
                        32.000  i/100ms
19x19 full playout (+ score)
                        12.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        713.264  (± 6.6%) i/s -     21.318k
13x13 full playout (+ score)
                        302.691  (±13.2%) i/s -      8.864k
19x19 full playout (+ score)
                        121.265  (±14.0%) i/s -      3.540k


Running jruby-1 with
Using /home/tobi/.rvm/gems/jruby-1.7.22
jruby 1.7.22 (1.9.3p551) 2015-08-20 c28f492 on OpenJDK 64-Bit Server VM 1.8.0_45-internal-b14 +jit [linux-amd64]
Calculating -------------------------------------
9x9 full playout (+ score)
                        36.000  i/100ms
13x13 full playout (+ score)
                        16.000  i/100ms
19x19 full playout (+ score)
                         6.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        353.815  (±12.7%) i/s -     10.404k
13x13 full playout (+ score)
                        163.234  (± 6.7%) i/s -      4.880k
19x19 full playout (+ score)
                         63.456  (±15.8%) i/s -      1.842k


Running 2.2 with
Using /home/tobi/.rvm/gems/ruby-2.2.3
ruby 2.2.3p173 (2015-08-18 revision 51636) [x86_64-linux]
Calculating -------------------------------------
9x9 full playout (+ score)
                        30.000  i/100ms
13x13 full playout (+ score)
                        12.000  i/100ms
19x19 full playout (+ score)
                         5.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        300.910  (± 7.6%) i/s -      8.970k
13x13 full playout (+ score)
                        131.262  (±12.2%) i/s -      3.864k
19x19 full playout (+ score)
                         55.403  (± 7.2%) i/s -      1.655k


Using /home/tobi/.rvm/gems/ruby-2.2.3 with gemset rubykon
Running truffle graal with enough heap space
$ JAVACMD=../graalvm-jdk1.8.0/bin/java ../jruby/bin/jruby -X\+T -Xtruffle.core.load_path\=../jruby/truffle/src/main/ruby -r ./.jruby\+truffle_bundle/bundler/setup.rb -e puts\ RUBY_DESCRIPTION
jruby 9.0.4.0-SNAPSHOT (2.2.2) 2015-11-08 fd2c179 OpenJDK 64-Bit Server VM 25.40-b25-internal-graal-0.7 on 1.8.0-internal-b132 +jit [linux-amd64]
$ JAVACMD=../graalvm-jdk1.8.0/bin/java ../jruby/bin/jruby -X\+T -J-Xmx1500m -Xtruffle.core.load_path\=../jruby/truffle/src/main/ruby -r ./.jruby\+truffle_bundle/bundler/setup.rb benchmark/full_playout.rb
Calculating -------------------------------------
9x9 full playout (+ score)
                        39.000  i/100ms
13x13 full playout (+ score)
                        44.000  i/100ms
19x19 full playout (+ score)
                        16.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                          1.060k (± 16.2%) i/s -     30.654k
13x13 full playout (+ score)
                        460.080  (± 17.0%) i/s -     13.332k
19x19 full playout (+ score)
                        192.420  (± 14.0%) i/s -      5.632k

```


### Full MCTS


```
Running 1.9.3 with
Using /home/tobi/.rvm/gems/ruby-1.9.3-p551
ruby 1.9.3p551 (2014-11-13 revision 48407) [x86_64-linux]
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         0.97 i/min  61.79 s (avg)  (± 6.59%)
13x13 2_000 iterations        2.1 i/min  28.6 s (avg)  (± 0.92%)
19x19 1_000 iterations        1.74 i/min  34.47 s (avg)  (± 0.36%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         0.91 i/min  66.29 s (avg)  (± 1.85%)
13x13 2_000 iterations        2.13 i/min  28.16 s (avg)  (± 1.31%)
19x19 1_000 iterations        1.61 i/min  37.26 s (avg)  (± 2.23%)
--------------------------------------------------------------------------------


Running jruby with
Using /home/tobi/.rvm/gems/jruby-9.0.3.0
jruby 9.0.3.0 (2.2.2) 2015-10-21 633c9aa OpenJDK 64-Bit Server VM 25.45-b02 on 1.8.0_45-internal-b14 +jit [linux-amd64]
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.84 i/min  32.63 s (avg)  (± 5.13%)
13x13 2_000 iterations        4.33 i/min  13.86 s (avg)  (± 2.28%)
19x19 1_000 iterations        3.62 i/min  16.56 s (avg)  (± 5.43%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.91 i/min  31.48 s (avg)  (± 2.48%)
13x13 2_000 iterations        4.33 i/min  13.86 s (avg)  (± 4.27%)
19x19 1_000 iterations        3.7 i/min  16.23 s (avg)  (± 2.48%)
--------------------------------------------------------------------------------


Running rbx-2.5.8 with
Using /home/tobi/.rvm/gems/rbx-2.5.8
rubinius 2.5.8 (2.1.0 bef51ae3 2015-11-08 3.4.2 JI) [x86_64-linux-gnu]
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished measuring the run time for 9x9 10_000 iterations
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished measuring the run time for 13x13 2_000 iterations
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Finished measuring the run time for 19x19 1_000 iterations
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.0 i/min  59.76 s (avg)  (± 5.83%)
13x13 2_000 iterations        2.48 i/min  24.21 s (avg)  (± 0.88%)
19x19 1_000 iterations        2.12 i/min  28.27 s (avg)  (± 1.55%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.07 i/min  56.05 s (avg)  (± 0.2%)
13x13 2_000 iterations        2.48 i/min  24.21 s (avg)  (± 0.8%)
19x19 1_000 iterations        2.1 i/min  28.52 s (avg)  (± 2.59%)
--------------------------------------------------------------------------------


Running jruby-9 with --server -Xcompile.invokedynamic=true -J-Xmx1500m
Using /home/tobi/.rvm/gems/jruby-9.0.3.0
jruby 9.0.3.0 (2.2.2) 2015-10-21 633c9aa OpenJDK 64-Bit Server VM 25.45-b02 on 1.8.0_45-internal-b14 +jit [linux-amd64]
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished measuring the run time for 9x9 10_000 iterations
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished measuring the run time for 13x13 2_000 iterations
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Finished measuring the run time for 19x19 1_000 iterations
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         3.53 i/min  17.02 s (avg)  (± 15.86%)
13x13 2_000 iterations        8.59 i/min  6.99 s (avg)  (± 1.21%)
19x19 1_000 iterations        6.96 i/min  8.62 s (avg)  (± 1.65%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         3.77 i/min  15.89 s (avg)  (± 1.87%)
13x13 2_000 iterations        8.52 i/min  7.04 s (avg)  (± 3.46%)
19x19 1_000 iterations        7.02 i/min  8.55 s (avg)  (± 1.92%)
--------------------------------------------------------------------------------


Running jruby-1 with
Using /home/tobi/.rvm/gems/jruby-1.7.22
jruby 1.7.22 (1.9.3p551) 2015-08-20 c28f492 on OpenJDK 64-Bit Server VM 1.8.0_45-internal-b14 +jit [linux-amd64]
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished measuring the run time for 9x9 10_000 iterations
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished measuring the run time for 13x13 2_000 iterations
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Finished measuring the run time for 19x19 1_000 iterations
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.97 i/min  30.51 s (avg)  (± 3.66%)
13x13 2_000 iterations        4.55 i/min  13.18 s (avg)  (± 3.45%)
19x19 1_000 iterations        3.87 i/min  15.52 s (avg)  (± 1.04%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         2.05 i/min  29.32 s (avg)  (± 1.21%)
13x13 2_000 iterations        4.57 i/min  13.13 s (avg)  (± 2.73%)
19x19 1_000 iterations        3.94 i/min  15.23 s (avg)  (± 1.61%)
--------------------------------------------------------------------------------


Running 2.2 with
Using /home/tobi/.rvm/gems/ruby-2.2.3
ruby 2.2.3p173 (2015-08-18 revision 51636) [x86_64-linux]
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished measuring the run time for 9x9 10_000 iterations
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished measuring the run time for 13x13 2_000 iterations
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Finished measuring the run time for 19x19 1_000 iterations
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.50 i/min  40.04 s (avg)  (± 0.83%)
13x13 2_000 iterations        3.35 i/min  17.90 s (avg)  (± 1.65%)
19x19 1_000 iterations        2.71 i/min  22.15 s (avg)  (± 0.37%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.47 i/min  40.68 s (avg)  (± 2.28%)
13x13 2_000 iterations        3.29 i/min  18.21 s (avg)  (± 0.44%)
19x19 1_000 iterations        2.72 i/min  22.09 s (avg)  (± 1.05%)
--------------------------------------------------------------------------------


Running truffle graal with enough heap space
$ JAVACMD=../graalvm-jdk1.8.0/bin/java ../jruby/bin/jruby -X\+T -Xtruffle.core.load_path\=../jruby/truffle/src/main/ruby -r ./.jruby\+truffle_bundle/bundler/setup.rb -e puts\ RUBY_DESCRIPTION
jruby 9.0.4.0-SNAPSHOT (2.2.2) 2015-11-08 fd2c179 OpenJDK 64-Bit Server VM 25.40-b25-internal-graal-0.7 on 1.8.0-internal-b132 +jit [linux-amd64]
$ JAVACMD=../graalvm-jdk1.8.0/bin/java ../jruby/bin/jruby -X\+T -J-Xmx1500m -Xtruffle.core.load_path\=../jruby/truffle/src/main/ruby -r ./.jruby\+truffle_bundle/bundler/setup.rb benchmark/mcts_avg.rb
Running your benchmark...
--------------------------------------------------------------------------------
Finished warm up for 9x9 10_000 iterations, running the real bechmarks now
Finished measuring the run time for 9x9 10_000 iterations
Finished warm up for 13x13 2_000 iterations, running the real bechmarks now
Finished measuring the run time for 13x13 2_000 iterations
Finished warm up for 19x19 1_000 iterations, running the real bechmarks now
Finished measuring the run time for 19x19 1_000 iterations
Benchmarking finished, here are your reports...

Warm up results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         1.88 i/min  31.86 s (avg)  (± 94.52%)
13x13 2_000 iterations        3.96 i/min  15.14 s (avg)  (± 159.39%)
19x19 1_000 iterations        9.65 i/min  6.22 s (avg)  (± 10.24%)

Runtime results:
--------------------------------------------------------------------------------
9x9 10_000 iterations         5.04 i/min  11.90 s (avg)  (± 7.95%)
13x13 2_000 iterations        13.86 i/min  4.33 s (avg)  (± 15.73%)
19x19 1_000 iterations        9.49 i/min  6.32 s (avg)  (± 8.33%)
--------------------------------------------------------------------------------
```


## 0.2 (Simplified board representation)

Notable is that these changes weren't done for performance reasons apparent in these benchmarks, as benchmark-ips does run GC so the lack of GC runs should not affect it. Maybe the benefit of creating less objects.

Some ruby versions showed no notable differences (rbx, jruby 9k) while others (CRuby, jruby 1.7) showed nice gains. On 19x19 CRuby 2.2.3 went 25 --> 34, jruby 1.7 went 43 --> 54.

```
Running rbx with
Using /home/tobi/.rvm/gems/rbx-2.5.2
Calculating -------------------------------------
9x9 full playout (+ score)
                         7.000  i/100ms
13x13 full playout (+ score)
                         4.000  i/100ms
19x19 full playout (+ score)
                         1.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        117.110  (± 7.7%) i/s -      2.331k
13x13 full playout (+ score)
                         53.714  (± 7.4%) i/s -      1.068k
19x19 full playout (+ score)
                         23.817  (±12.6%) i/s -    467.000 
Running 1.9.3 with
Using /home/tobi/.rvm/gems/ruby-1.9.3-p551
Calculating -------------------------------------
9x9 full playout (+ score)
                        15.000  i/100ms
13x13 full playout (+ score)
                         6.000  i/100ms
19x19 full playout (+ score)
                         2.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        149.826  (± 6.0%) i/s -      3.000k
13x13 full playout (+ score)
                         66.382  (± 9.0%) i/s -      1.320k
19x19 full playout (+ score)
                         28.114  (±10.7%) i/s -    554.000 
Running jruby-dev-graal with -X+T -J-Xmx1500m
Using /home/tobi/.rvm/gems/jruby-dev-graal
Calculating -------------------------------------
9x9 full playout (+ score)
                         1.000  i/100ms
13x13 full playout (+ score)
                         1.000  i/100ms
19x19 full playout (+ score)
                         1.000  i/100ms
Calculating -------------------------------------
9x9 full playout (+ score)
                          9.828  (± 40.7%) i/s -    158.000 
13x13 full playout (+ score)
                          4.046  (± 24.7%) i/s -     70.000 
19x19 full playout (+ score)
                          5.289  (± 37.8%) i/s -     87.000 
Running jruby with
Using /home/tobi/.rvm/gems/jruby-9.0.1.0
Calculating -------------------------------------
9x9 full playout (+ score)
                        11.000  i/100ms
13x13 full playout (+ score)
                        10.000  i/100ms
19x19 full playout (+ score)
                         4.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        243.322  (± 7.8%) i/s -      4.829k
13x13 full playout (+ score)
                        105.500  (± 6.6%) i/s -      2.100k
19x19 full playout (+ score)
                         45.046  (± 8.9%) i/s -    896.000 
Running jruby-1 with
Using /home/tobi/.rvm/gems/jruby-1.7.22
Calculating -------------------------------------
9x9 full playout (+ score)
                        14.000  i/100ms
13x13 full playout (+ score)
                        12.000  i/100ms
19x19 full playout (+ score)
                         5.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        279.079  (±11.8%) i/s -      5.488k
13x13 full playout (+ score)
                        128.978  (± 7.0%) i/s -      2.568k
19x19 full playout (+ score)
                         54.526  (± 9.2%) i/s -      1.085k
Running 2.2 with
Using /home/tobi/.rvm/gems/ruby-2.2.3
Calculating -------------------------------------
9x9 full playout (+ score)
                        18.000  i/100ms
13x13 full playout (+ score)
                         8.000  i/100ms
19x19 full playout (+ score)
                         3.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        183.983  (± 4.9%) i/s -      3.672k
13x13 full playout (+ score)
                         80.525  (± 6.2%) i/s -      1.608k
19x19 full playout (+ score)
                         34.117  (± 8.8%) i/s -    678.000 
```

## 0.1 (first really naive implementation)

```
Running rbx with
Using /home/tobi/.rvm/gems/rbx-2.5.2
Calculating -------------------------------------
9x9 full playout (+ score)
                         4.000  i/100ms
13x13 full playout (+ score)
                         3.000  i/100ms
19x19 full playout (+ score)
                         1.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        112.237  (±11.6%) i/s -      2.212k
13x13 full playout (+ score)
                         52.475  (± 9.5%) i/s -      1.041k
19x19 full playout (+ score)
                         22.600  (±13.3%) i/s -    442.000 
Running 1.9.3 with
Using /home/tobi/.rvm/gems/ruby-1.9.3-p551
Calculating -------------------------------------
9x9 full playout (+ score)
                        10.000  i/100ms
13x13 full playout (+ score)
                         4.000  i/100ms
19x19 full playout (+ score)
                         2.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        111.529  (± 8.1%) i/s -      2.220k
13x13 full playout (+ score)
                         48.059  (±10.4%) i/s -    952.000 
19x19 full playout (+ score)
                         19.788  (±15.2%) i/s -    390.000 
Running jruby-dev-graal with -X+T -J-Xmx1500m
Using /home/tobi/.rvm/gems/jruby-dev-graal
Calculating -------------------------------------
9x9 full playout (+ score)
                         1.000  i/100ms
13x13 full playout (+ score)
                         1.000  i/100ms
19x19 full playout (+ score)
                         1.000  i/100ms
Calculating -------------------------------------
9x9 full playout (+ score)
                          5.787  (± 34.6%) i/s -    102.000 
13x13 full playout (+ score)
                          3.598  (± 27.8%) i/s -     67.000 
19x19 full playout (+ score)
                          1.849  (± 0.0%) i/s -     36.000 
Running jruby with
Using /home/tobi/.rvm/gems/jruby-9.0.1.0
Calculating -------------------------------------
9x9 full playout (+ score)
                         9.000  i/100ms
13x13 full playout (+ score)
                        10.000  i/100ms
19x19 full playout (+ score)
                         4.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        237.441  (±11.0%) i/s -      4.680k
13x13 full playout (+ score)
                        105.639  (± 9.5%) i/s -      2.090k
19x19 full playout (+ score)
                         44.741  (±11.2%) i/s -    884.000 
Running jruby-1 with
Using /home/tobi/.rvm/gems/jruby-1.7.22
Calculating -------------------------------------
9x9 full playout (+ score)
                        11.000  i/100ms
13x13 full playout (+ score)
                         9.000  i/100ms
19x19 full playout (+ score)
                         4.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        224.768  (±15.6%) i/s -      4.356k
13x13 full playout (+ score)
                        105.326  (± 7.6%) i/s -      2.097k
19x19 full playout (+ score)
                         43.576  (±11.5%) i/s -    864.000 
Running 2.2 with
Using /home/tobi/.rvm/gems/ruby-2.2.3
Calculating -------------------------------------
9x9 full playout (+ score)
                        14.000  i/100ms
13x13 full playout (+ score)
                         6.000  i/100ms
19x19 full playout (+ score)
                         2.000  i/100ms
-------------------------------------------------
9x9 full playout (+ score)
                        139.838  (± 6.4%) i/s -      2.786k
13x13 full playout (+ score)
                         60.935  (± 8.2%) i/s -      1.212k
19x19 full playout (+ score)
                         25.423  (±11.8%) i/s -    502.000
```
