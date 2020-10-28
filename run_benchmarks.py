#!/usr/bin/env python3

import argparse
import subprocess
import csv
import os

# Path to the Ruby benchmark harness dir
HARNESS_LIB_DIR = './lib'

# TODO: quick test mode, --quick ?
# TODO: compare with and without microjit

def run_benchmarks(enable_ujit):
    """
    Run all the benchmarks and record execution times
    """

    bench_times = {}

    for entry in sorted(os.listdir('benchmarks')):
        bench_name = entry.rstrip('.rb')

        # Path to the benchmark runner script
        script_path = os.path.join('benchmarks', entry)
        if not script_path.endswith('.rb'):
            script_path = os.path.join(script_path, 'benchmark.rb')

        print(script_path)

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
        subprocess.check_call(cmd, env=sub_env)

        with open(sub_env["OUT_CSV_PATH"]) as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')
            rows = list(reader)
            times = list(map(lambda v: float(v), rows[0]))

        print(times)

        bench_times[bench_name] = times

    return bench_times

ujit_times = run_benchmarks(enable_ujit=True)
interp_times = run_benchmarks(enable_ujit=False)

print(ujit_times)
