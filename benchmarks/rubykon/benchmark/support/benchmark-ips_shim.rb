# Shim modifying benchmark-ips to work better with truffle,
# written by Chris Seaton and taken from:
# https://gist.github.com/chrisseaton/1c4cb91f3c95ddcf2d1e
# Note that this has very little effect on the performance of CRuby/JRuby.
# I tried it out and results were ~2 to 4 % better which is well within
# the tolerance. On a pre 0.3 version this moved truffle fromm 33 ips of
# 19x19 gameplay up to 169.

# This file modifies benchmark-ips to better accommodate the optimisation
# characteristics of sophisticated implementations of Ruby that have a very
# large difference between cold and warmed up performance, and that apply
# optimisations such as value profiling or other speculation on runtime values.
# Recommended to be used with a large (60s) warmup and (30s) measure time. This
# has been modified to be the default. Note that on top of that, it now runs
# warmup five times, so generating the report will be a lot slower than
# before.

# Code is modified from benchmark-ips

# Copyright (c) 2015 Evan Phoenix
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Benchmark
  module IPS
    class Job

      def run_warmup
        @list.each do |item|
          @suite.warming item.label, @warmup if @suite

          unless @quiet
            $stdout.print item.label_rjust
          end

          Timing.clean_env

          # Modification - run with different iteration parameters to defeat
          # value profiling and other speculation on runtime values.

          item.call_times 1
          item.call_times 2
          item.call_times 3

          # Modification - actual time to warm up - not measured

          target = Time.now + @warmup
          while Time.now < target
            item.call_times 1
          end

          before = Time.now
          target = Time.now + @warmup

          warmup_iter = 0

          while Time.now < target
            item.call_times(1)
            warmup_iter += 1
          end

          after = Time.now

          warmup_time_us = time_us before, after

          @timing[item] = cycles_per_100ms warmup_time_us, warmup_iter

          # Modification - warm up again with this new iteration value that we
          # haven't run before.

          cycles = @timing[item]
          target = Time.now + @warmup

          while Time.now < target
            item.call_times cycles
          end

          # Modification repeat the scaling again

          before = Time.now
          target = Time.now + @warmup

          warmup_iter = 0

          while Time.now < target
            item.call_times cycles
            warmup_iter += cycles
          end

          after = Time.now

          warmup_time_us = time_us before, after

          @timing[item] = cycles_per_100ms warmup_time_us, warmup_iter

          case Benchmark::IPS.options[:format]
          when :human
            $stdout.printf "%s i/100ms\n", Helpers.scale(@timing[item]) unless @quiet
          else
            $stdout.printf "%10d i/100ms\n", @timing[item] unless @quiet
          end

          @suite.warmup_stats warmup_time_us, @timing[item] if @suite

          # Modification - warm up again with this new iteration value that we
          # haven't run before.

          cycles = @timing[item]
          target = Time.now + @warmup

          while Time.now < target
            item.call_times cycles
          end
        end
      end

      alias_method :old_initialize, :initialize

      def initialize opts={}
        old_initialize opts
        @warmup = 60
        @time = 30
      end

    end
  end
end
