import sys
import os
import math
import subprocess

def get_ruby_version():
    ruby_version = subprocess.check_output(["ruby", "-v"])
    ruby_version = str(ruby_version, 'utf-8').replace('\n', ' ')
    print(ruby_version)

    if not "MicroJIT" in ruby_version:
        print("You forgot to chruby to ruby-microjit:")
        print("  chruby ruby-microjit")
        sys.exit(-1)

    return ruby_version

def check_pstate():
    if not os.path.exists('/sys/devices/system/cpu/intel_pstate/no_turbo'):
        return

    with open('/sys/devices/system/cpu/intel_pstate/no_turbo', mode='r') as file:
        content = file.read().strip()

    if content != '1':
        print("You forgot to disable turbo:")
        print("  sudo sh -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'")
        sys.exit(-1)

    if not os.path.exists('/sys/devices/system/cpu/intel_pstate/min_perf_pct'):
        return

    with open('/sys/devices/system/cpu/intel_pstate/min_perf_pct', mode='r') as file:
        content = file.read().strip()

    if content != '100':
        print("You forgot to set the min perf percentage to 100:")
        print("  sudo sh -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct'")
        sys.exit(-1)

def table_to_str(table_data):
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

    return tabulate(table_data)

def mean(values):
    total = sum(values)
    return total / len(values)

def stddev(values):
    xbar = mean(values)
    diff_sqrs = map(lambda v: (v-xbar)*(v-xbar), values)
    mean_sqr = sum(diff_sqrs) / len(values)
    return math.sqrt(mean_sqr)

def free_file_no():
    for file_no in range(1, 1000):
        out_path = 'output_{:03d}.csv'.format(file_no)
        if not os.path.exists(out_path):
            return file_no
    assert False
