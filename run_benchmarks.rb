#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'fileutils'
require 'shellwords'

def check_call(args)
  command = args.shelljoin
  status = system(command)
  raise RuntimeError unless status
end

def check_output(args)
  output = IO.popen(args).read
  raise RuntimeError unless $?
  return output
end

def build_ujit(repo_dir)
    if !File.exist?(repo_dir)
        puts('Directory does not exist "' + repo_dir + '"')
        exit(-1)
    end

    Dir.chdir(repo_dir) do
        check_call(['git', 'pull'])

        # Don't do a clone and configure every time
        # ./config.status --config => check that DRUBY_DEBUG is not in there
        config_out = check_output(['./config.status', '--config'])

        if config_out.include?("DRUBY_DEBUG")
            puts("You should configure MicroJIT in release mode for benchmarking")
            exit(-1)
        end

        # Build in parallel
        #n_cores = os.cpu_count()
        n_cores = 32
        #puts("Building MicroJIT with #{n_cores} processes")
        check_call(['make', '-j' + n_cores.to_s, 'install'])
    end
end



=begin
def set_bench_config():
     # sudo requires the flag '-S' in order to take input from stdin
     subprocess.check_call("sudo -S sh -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'", shell=True)
     subprocess.check_call("sudo -S sh -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct'", shell=True)

def get_ruby_version():
    ruby_version = subprocess.check_output(["ruby", "-v"])
    ruby_version = str(ruby_version, 'utf-8').replace('\n', ' ')
    print(ruby_version)

    if not "ujit" in ruby_version.lower():
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

def free_file_no(out_path):
    for file_no in range(1, 1000):
        out_path = os.path.join(out_path, 'output_{:03d}.csv'.format(file_no))
        if not os.path.exists(out_path):
            return file_no
    assert False
=end




























=begin
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
=end




=begin

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

=end











args = OpenStruct.new({
    repo_dir: "../microjit",
    out_path: "./data",
    name_filters: ['']
})

OptionParser.new do |opts|
  #opts.banner = "Usage: example.rb [options]"
  opts.on("--repo_dir=REPO_DIR") do |v|
    args.repo_dir = v
  end

  opts.on("--out_path=OUT_PATH", "directory where to store output data files") do |v|
    args.out_path = v
  end

  opts.on("--name_filters x,y,z", Array, "when given, only benchmarks with names that contain one of these strings will run") do |list|
    args.name_filters = list
  end

  opts.on("--out_path=OUT_PATH") do |v|
    args[:out_path] = v
  end

end.parse!

# Create the output directory
FileUtils.mkdir_p(args.out_path)

# Update and build MicroJIT
build_ujit(args.repo_dir)


=begin
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

=end