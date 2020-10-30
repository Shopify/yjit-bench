#!/usr/bin/env python3

import argparse
import subprocess
import csv
import os
import json
import time
import datetime
from utils import *

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

        # Set up the benchmarking command
        cmd = [
            "perf", "stat", "-e", "cycles:u",
            "ruby",
            "--ujit" if enable_ujit else "--disable-ujit",
            "-I", "./harness-perf",
            script_path
        ]

        times = []

        # Do the benchmarking
        for i in range(4):
            print(cmd)
            cmd_output = subprocess.check_output(cmd)
            lines = cmd_output.split('\n')
            lines = map(lambda l: l.strip())

            for line in lines:
                tokens = line.split()
                if tokens[1] == 'cycles:u':
                    times.append(int(tokens[0]))
                    break

        bench_times[bench_name] = times

    return bench_times

ruby_version = get_ruby_version()

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

# Find a free file index for the output files
file_no = free_file_no()

# Save data as CSV so we can produce tables/graphs in a spreasheet program
# NOTE: we don't do any number formatting for the output file because
#       we don't want to lose any precision
output_tbl = [[ruby_version], []] + table
with open('output_{:03d}.csv'.format(file_no), 'w') as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='"')
    writer.writerow(output_tbl)

# Save the output in a text file that we can easily refer to
output_str = ruby_version + '\n' + table_to_str(table) + '\n'
with open('output_{:03d}.txt'.format(file_no), 'w') as txtfile:
    txtfile.write(output_str)

# Print the table to the console, with numbers truncated
print(output_str)
