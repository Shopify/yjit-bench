#!/usr/bin/env python3

import argparse
import subprocess
import csv
import os
import json
import time

# Path to the Ruby benchmark harness dir
HARNESS_LIB_DIR = './lib'

def run_benchmarks(enable_ujit):
    """
    Run all the benchmarks and record execution times
    """

    bench_times = {}

    for entry in sorted(os.listdir('benchmarks')):
        bench_name = entry.replace('.rb', '')

        # Path to the benchmark runner script
        script_path = os.path.join('benchmarks', entry)
        if not script_path.endswith('.rb'):
            script_path = os.path.join(script_path, 'benchmark.rb')

        # Set up the environment for the benchmarking command
        sub_env = os.environ.copy()
        sub_env["OUT_CSV_PATH"] = 'output.csv'

        # Set up the benchmarking command
        cmd = [
            "ruby",
            "--ujit" if enable_ujit else "--disable-ujit",
            "-I", HARNESS_LIB_DIR,
            script_path
        ]

        # Do the benchmarking
        print(cmd)
        subprocess.check_call(cmd, env=sub_env)

        with open(sub_env["OUT_CSV_PATH"]) as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')
            rows = list(reader)
            # Convert times to ms
            times = list(map(lambda v: 1000 * float(v), rows[0]))

        #print(times)
        #print(mean(times))
        #print(stddev(times))

        bench_times[bench_name] = times

    return bench_times

def print_table(table_data):
    from tabulate import tabulate

    def trim_cell(cell):
        try:
            return '{:.1f}'.format(cell)
        except:
            return cell

    def trim_row(row):
        return list(map(lambda c: trim_cell(c), row))

    # Trim numbers to one decimal for console display
    table_data = list(map(trim_row, table_data))

    print(tabulate(table_data))

def mean(values):
    total = sum(values)
    return total / len(values)

def stddev(values):
    import math
    xbar = mean(values)
    diff_sqrs = map(lambda v: (v-xbar)*(v-xbar), values)
    mean_sqr = sum(diff_sqrs) / len(values)
    return math.sqrt(mean_sqr)

# TODO: argparse
# TODO: quick test mode, --quick ?
# TODO: compare with and without microjit

ruby_version = subprocess.check_output(["ruby", "-v"])
ruby_version = str(ruby_version, 'utf-8').replace('\n', ' ')
print(ruby_version)
assert "MicroJIT" in ruby_version

bench_start_time = time.time()
ujit_times = run_benchmarks(enable_ujit=True)
interp_times = run_benchmarks(enable_ujit=False)
bench_end_time = time.time()
bench_names = sorted(ujit_times.keys())

bench_total_time = int(bench_end_time - bench_start_time)
print('Total time spent benchmarking: {}s'.format(bench_total_time))
print()

# Table for the data we've gathered
table = [["bench", "interp (ms)", "stddev (%)", "ujit (ms)", "stddev (%)", "speedup (%)"]]

for bench_name in bench_names:
    ujit_t = ujit_times[bench_name]
    interp_t = interp_times[bench_name]

    speedup = 100 * (1 - (mean(ujit_t) / mean(interp_t)))

    table.append([
        bench_name,
        mean(interp_t),
        100 * stddev(interp_t) / mean(interp_t),
        mean(ujit_t),
        100 * stddev(ujit_t) / mean(ujit_t),
        speedup
    ])

# Save data as CSV so we can produce tables/graphs in a spreasheet program
# NOTE: we don't do any number formatting for the output file because
#       we don't want to lose any precision
table = [[ruby_version], []] + table
with open('table.csv', 'w') as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='"')
    writer.writerow(table)

# Print the table to the console, with numbers truncated
print_table(table)
