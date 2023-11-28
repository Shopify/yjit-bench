# Ensure the ruby in PATH is the ruby running this, so we can safely shell out to other commands
ruby_in_path = `ruby -e 'print RbConfig.ruby'`
unless ruby_in_path == RbConfig.ruby
  abort "The ruby running this script (#{RbConfig.ruby}) is not the first ruby in PATH (#{ruby_in_path})"
end

# Support enabling GC auto-compaction via environment variable
GC.auto_compact = !!ENV["RUBY_GC_AUTO_COMPACT"]

# Seed the global random number generator for repeatability between runs
Random.srand(1337)

def run_cmd(*args)
  puts "Command: #{args.join(" ")}"
  system(*args)
end

def setup_cmds(c)
  c.each do |cmd|
    success = run_cmd(cmd)
    raise "Couldn't run setup command for benchmark in #{Dir.pwd.inspect}!" unless success
  end
end

# Set up a Gemfile, install gems and do extra setup
def use_gemfile(extra_setup_cmd: nil)
  # Benchmarks should normally set their current directory and then call this method.

  setup_cmds(["bundle check 2> /dev/null || bundle install", extra_setup_cmd].compact)

  # Need to be in the appropriate directory for this...
  require "bundler/setup"
end

# This returns its best estimate of the Resident Set Size in bytes.
# That's roughly the amount of memory the process takes, including shareable resources.
# RSS reference: https://stackoverflow.com/questions/7880784/what-is-rss-and-vsz-in-linux-memory-management
def get_rss
  mem_rollup_file = "/proc/#{Process.pid}/smaps_rollup"
  if File.exist?(mem_rollup_file)
    # First, grab a line like "62796 kB". Checking the Linux kernel source, Rss will always be in kB.
    rss_desc = File.read(mem_rollup_file).lines.detect { |line| line.start_with?("Rss") }.split(":", 2)[1][/(\d+)/, 1]
    1024 * Integer(rss_desc)
  else
    # Collect our own peak mem usage as soon as reasonable after finishing the last iteration.
    # This method is only accurate to kilobytes, but is nicely portable and doesn't require
    # any extra gems/dependencies.
    mem = `ps -o rss= -p #{Process.pid}`
    1024 * Integer(mem)
  end
end

def get_maxrss
  require 'fiddle'
  require 'rbconfig/sizeof'

  unless Fiddle::SIZEOF_LONG == 8 and RbConfig::CONFIG["host_os"] =~ /linux|darwin/
    # The code below assumes 64-bit alignment and Linux or macOS
    return 0
  end

  libc = Fiddle.dlopen(nil)
  getrusage = Fiddle::Function.new(libc['getrusage'], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)

  buffer = "\0".b * 1024 # more than enough, the actual struct is about 144 bytes
  sizeof_timeval = RbConfig::SIZEOF['time_t'] + Fiddle::SIZEOF_LONG
  offset = sizeof_timeval * 2
  rusage_self = 0
  result = getrusage.call(rusage_self, buffer)
  raise unless result.zero?
  maxrss_kb = buffer[offset, Fiddle::SIZEOF_LONG].unpack1('q')
  1024 * maxrss_kb
end

# Do expand_path at require-time, not when returning results, before the benchmark is likely to chdir
default_path = "data/results-#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}-#{Time.now.strftime('%F-%H%M%S')}.json"
yb_env_var = ENV.fetch("RESULT_JSON_PATH", default_path)
YB_OUTPUT_FILE = File.expand_path yb_env_var

def return_results(warmup_iterations, bench_iterations)
  yjit_bench_results = {
    "RUBY_DESCRIPTION" => RUBY_DESCRIPTION,
    "warmup" => warmup_iterations,
    "bench" => bench_iterations,
  }

  # Collect our own peak mem usage as soon as reasonable after finishing the last iteration.
  rss = get_rss
  maxrss = get_maxrss
  puts "RSS: %.1fMiB" % (rss / 1024.0 / 1024.0)
  puts "MAXRSS: %.1fMiB" % (maxrss / 1024.0 / 1024.0)
  yjit_bench_results["rss"] = rss
  yjit_bench_results["maxrss"] = maxrss

  if defined?(RubyVM::YJIT) && RubyVM::YJIT.stats_enabled?
    yjit_bench_results["yjit_stats"] = RubyVM::YJIT.runtime_stats
  end

  require "json"
  out_path = YB_OUTPUT_FILE
  system('mkdir', '-p', File.dirname(out_path))

  # Using default path? Print where we put it.
  puts "Writing file #{out_path}" unless ENV["RESULT_JSON_PATH"]

  File.write(out_path, JSON.pretty_generate(yjit_bench_results))
end
