import sys
import os
import math
import subprocess

def build_yjit(repo_dir):
    cwd = os.getcwd()

    if not os.path.exists(repo_dir):
        print('Directory does not exist "' + repo_dir + '"')
        sys.exit(-1)

    # Change to the YJIT directory
    os.chdir(repo_dir)

    subprocess.check_call(['git', 'pull'])

    # Don't do a clone and configure every time
    # ./config.status --config => check that DRUBY_DEBUG is not in there
    config_out = subprocess.check_output(['./config.status', '--config'])

    if "DRUBY_DEBUG" in str(config_out):
        print("You should configure YJIT in release mode for benchmarking")
        sys.exit(-1)

    # Build in parallel
    n_cores = os.cpu_count()
    print('Building YJIT with {} processes'.format(n_cores))
    subprocess.check_call(['make', '-j' + str(n_cores), 'install'])

    os.chdir(cwd)

def set_bench_config():
     if os.path.exists('/sys/devices/system/cpu/intel_pstate'):
         # sudo requires the flag '-S' in order to take input from stdin
         subprocess.check_call("sudo -S sh -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'", shell=True)
         subprocess.check_call("sudo -S sh -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct'", shell=True)

def get_ruby_version():
    ruby_version = subprocess.check_output(["ruby", "-v"])
    ruby_version = str(ruby_version, 'utf-8').replace('\n', ' ')
    print(ruby_version)

    if not "yjit" in ruby_version.lower():
        print("You forgot to chruby to ruby-yjit:")
        print("  chruby ruby-yjit")
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

def free_file_no(out_path):
    for file_no in range(1, 1000):
        out_path = os.path.join(out_path, 'output_{:03d}.csv'.format(file_no))
        if not os.path.exists(out_path):
            return file_no
    assert False
