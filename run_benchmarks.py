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

        # Set up the environment for the benchmarking command
        sub_env = os.environ.copy()
        sub_env["OUT_CSV_PATH"] = 'output.csv'

        # Set up the benchmarking command
        cmd = [
            "nice", "-20",
            "taskset", "-c", "11",
            "ruby",
            "--ujit" if enable_ujit else "--disable-ujit",
            "-I", "./harness",
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
            times = sorted(times)

        #print(times)
        #print(mean(times))
        #print(stddev(times))

        bench_times[bench_name] = times

    return bench_times

# Get the ruby binary version string
ruby_version = get_ruby_version()

# Check that turbo is disabled
check_no_turbo()

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

# Format the results table
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

# Save the raw data
with open('output_{:03d}.json'.format(file_no), "w") as write_file:
    data = {
        'ujit': ujit_times,
        'interp': interp_times,
        'ruby_version': ruby_version,
    }
    json.dump(data, write_file, indent=4)

# Print the table to the console, with numbers truncated
print(output_str)
