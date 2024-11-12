# Ensure the ruby in PATH is the ruby running this, so we can safely shell out to other commands
ruby_in_path = `ruby -e 'print RbConfig.ruby'`
unless ruby_in_path == RbConfig.ruby
  ENV["PATH"] = "#{File.dirname(RbConfig.ruby)}:#{ENV["PATH"]}"
  ENV.merge!("GEM_HOME" => nil, "GEM_PATH" => nil) # avoid installing gems to chruby-ed Ruby
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

def is_macos
  RbConfig::CONFIG['host_os'].match(/darwin/) != nil
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

  # On macos, this value is already in bytes
  # (and the manpage is wrong)
  if is_macos
    maxrss_kb
  else
    1024 * maxrss_kb
  end
rescue LoadError
  warn "Failed to get max RSS: #{$!.message}"
  nil
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
  yjit_bench_results["rss"] = rss
  if maxrss = get_maxrss
    yjit_bench_results["maxrss"] = maxrss
  end

  if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
    yjit_stats = RubyVM::YJIT.runtime_stats
    yjit_bench_results["yjit_stats"] = yjit_stats

    formatted_stats = proc { |key| "%10s" % yjit_stats[key].to_s.reverse.scan(/\d{1,3}/).join(",").reverse }
    yjit_stats_keys = [
      *ENV.fetch("YJIT_BENCH_STATS", "").split(",").map(&:to_sym),
      :inline_code_size,
      :outlined_code_size,
      :code_region_size,
      :yjit_alloc_size,
      :compile_time_ns,
    ].uniq
    yjit_stats_pads = yjit_stats_keys.map(&:size).max + 1
    yjit_stats_keys.each do |key|
      if key == :compile_time_ns
        puts "#{"yjit_compile_time:".ljust(yjit_stats_pads)} %8.2fms" % (yjit_stats[:compile_time_ns] / 1_000_000.0).round(2)
      else
        puts "#{"#{key}:".ljust(yjit_stats_pads)} #{formatted_stats[key]}"
      end
    end
  end

  puts "RSS: %.1fMiB" % (rss / 1024.0 / 1024.0)
  if maxrss
    puts "MAXRSS: %.1fMiB" % (maxrss / 1024.0 / 1024.0)
  end

  write_json_file(yjit_bench_results)
end

def write_json_file(yjit_bench_results)
  require "json"

  out_path = YB_OUTPUT_FILE
  system('mkdir', '-p', File.dirname(out_path))

  # Using default path? Print where we put it.
  puts "Writing file #{out_path}" unless ENV["RESULT_JSON_PATH"]

  File.write(out_path, JSON.pretty_generate(yjit_bench_results))
rescue LoadError
  warn "Failed to write JSON file: #{$!.message}"
end
