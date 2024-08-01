# frozen_string_literal: true

def ensure_global_gem(name)
  found = Gem.find_latest_files(name).first
  unless found
    Gem.install(name)
    found = Gem.find_latest_files(name).first
  end
  warn "Adding to load path: #{File.dirname(found)}"
  $LOAD_PATH << File.dirname(found)
end

def ensure_global_gem_exe(name, exe = name)
  Gem.bin_path(name, exe)
rescue Gem::GemNotFoundException
  Gem.install(name)
end

def gem_exe(*args)
  # Remove any bundler env from the benchmark, let the exe figure it out.
  system({'RUBYOPT' => '', 'BUNDLER_SETUP' => nil}, *args)
end

def benchmark_name
  $0.match(%r{([^/]+?)(?:(?:/benchmark)?\.rb)?$})[1]
end

def harness_name
  $LOADED_FEATURES.reverse_each do |feat|
    if m = feat.match(%r{/harness-([^/]+)/harness\.rb$})
      return m[1]
    end
  end
  raise "Unable to determine harness name"
end

# Share a single timestamp for everything from this execution.
TIMESTAMP = Time.now.strftime('%F-%H%M%S')

def output_file_path(prefix: harness_name, suffix: benchmark_name, ruby_info: ruby_version_info, timestamp: TIMESTAMP, ext: "bin")
  File.expand_path("../data/#{prefix}-#{timestamp}-#{ruby_info}-#{suffix}.#{ext}", __dir__)
end

# Can we get the benchmark config name from somewhere?
def ruby_version_info
  "#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}"
end

def get_time
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

MIN_BENCH_TIME = Integer(ENV.fetch('MIN_BENCH_TIME', 10))
def run_enough_to_profile(n, &block)
  start = get_time
  loop do
    # Allow MIN_BENCH_ITRS to override the argument.
    n = ENV.fetch('MIN_BENCH_ITRS', n).to_i
    n.times(&block)

    break if (get_time - start) >= MIN_BENCH_TIME
  end
end
