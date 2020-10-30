import os
import math
import subprocess

def get_ruby_version():
    ruby_version = subprocess.check_output(["ruby", "-v"])
    ruby_version = str(ruby_version, 'utf-8').replace('\n', ' ')
    print(ruby_version)
    assert "MicroJIT" in ruby_version
    return ruby_version

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
