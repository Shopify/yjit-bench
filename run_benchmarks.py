#!/usr/bin/env python3

import argparse
import subprocess
import csv
import os
import json
import time
import datetime
from utils import *

def match_filter(name, filters):
    """
    Check if the name matches any of the names in a list of filters
    """

    if len(filters) == 0:
        return True

    for filter in filters:
        if filter in name:
            return True
    return False

def run_benchmarks(enable_ujit, name_filters, out_path):
    """
    Run all the benchmarks and record execution times
    """

    bench_times = {}

    for entry in sorted(os.listdir('benchmarks')):
        bench_name = entry.replace('.rb', '')

        if not match_filter(bench_name, name_filters):
            continue

        # Path to the benchmark runner script
        script_path = os.path.join('benchmarks', entry)
        if not script_path.endswith('.rb'):
            script_path = os.path.join(script_path, 'benchmark.rb')

        # Set up the environment for the benchmarking command
        sub_env = os.environ.copy()
        sub_env["OUT_CSV_PATH"] = os.path.join(out_path, 'temp.csv')

        # Set up the benchmarking command
        cmd = [
            # Disable address space randomization (for determinism)
            "setarch", "x86_64", "-R",
            # Increase process priority
            "nice", "-20",
            # Pin the process to one given core
            "taskset", "-c", "11",
            # Run the benchmark
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

parser = argparse.ArgumentParser(description='Run MicroJIT benchmarks.')
parser.add_argument('--repo_dir', type=str, default='../microjit', help='directory where the ujit repo is cloned')
parser.add_argument('--out_path', type=str, default='./data', help='directory where to store output data files')
parser.add_argument('name_filters', type=str, nargs='*', default=[''], help='when given, only benchmarks with names that contain one of these strings will run')
args = parser.parse_args()

# Create the output directory
os.makedirs(args.out_path, exist_ok=True)

# Update and build MicroJIT
build_ujit(args.repo_dir)

# Disable CPU frequency scaling
set_bench_config()

# Get the ruby binary version string
ruby_version = get_ruby_version()

# Check pstate status
check_pstate()

bench_start_time = time.time()
ujit_times = run_benchmarks(enable_ujit=True, name_filters=args.name_filters, out_path=args.out_path)
interp_times = run_benchmarks(enable_ujit=False, name_filters=args.name_filters, out_path=args.out_path)
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
file_no = free_file_no(args.out_path)

# Save data as CSV so we can produce tables/graphs in a spreasheet program
# NOTE: we don't do any number formatting for the output file because
#       we don't want to lose any precision
output_tbl = [[ruby_version], []] + table
out_tbl_path = os.path.join(args.out_path, 'output_{:03d}.csv'.format(file_no))
with open(out_tbl_path , 'w') as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='"')
    writer.writerow(output_tbl)

# Save the output in a text file that we can easily refer to
output_str = ruby_version + '\n' + table_to_str(table) + '\n'
out_txt_path = os.path.join(args.out_path, 'output_{:03d}.txt'.format(file_no))
with open(out_txt_path.format(file_no), 'w') as txtfile:
    txtfile.write(output_str)

# Save the raw data
out_json_path = os.path.join(args.out_path, 'output_{:03d}.json'.format(file_no))
with open(out_json_path, "w") as write_file:
    data = {
        'ujit': ujit_times,
        'interp': interp_times,
        'ruby_version': ruby_version,
    }
    json.dump(data, write_file, indent=4)

# Print the table to the console, with numbers truncated
print(output_str)
