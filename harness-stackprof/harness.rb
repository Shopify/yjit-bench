# frozen_string_literal: true

# Usage:
# STACKPROF_OPTS='mode:object' MIN_BENCH_TIME=0 MIN_BENCH_ITRS=1 ruby -v -I harness-stackprof benchmarks/.../benchmark.rb
# STACKPROF_OPTS='interval:10,mode:cpu' MIN_BENCH_TIME=1 MIN_BENCH_ITRS=10 ruby -v -I harness-stackprof benchmarks/.../benchmark.rb

require "yaml"

require_relative "../harness/harness-common"
require_relative "../harness/harness-extra"

ensure_global_gem("stackprof")

BOOLS = {"true" => true, "false" => false}
def bool!(val)
  case val
  when TrueClass, FalseClass
    val
  else
    BOOLS.fetch(val) { raise ArgumentError, "must be 'true' or 'false'" }
  end
end

DEFAULTS = {
  aggregate: true,
  raw: true,
}

def parse_opts_string(str)
  return {} unless str

  str.split(/,/).map { |x| x.strip.split(/[=:]/, 2) }.to_h.transform_keys(&:to_sym)
end

def stackprof_opts
  opts = DEFAULTS.merge(parse_opts_string(ENV['STACKPROF_OPTS']))

  bool = method(:bool!)

  {
    aggregate: bool,
    raw: bool,
    mode: :to_sym,
    interval: :to_i,
  }.each do |key, method|
    next unless opts.key?(key)

    method = proc(&method) if method.is_a?(Symbol)
    opts[key] = method.call(opts[key])
  rescue => error
    raise ArgumentError, "Option '#{key}' failed to convert: #{error}"
  end

  opts
end

def run_benchmark(n, &block)
  require "stackprof"

  opts = stackprof_opts
  prefix = "stackprof"
  prefix = "#{prefix}-#{opts[:mode]}" if opts[:mode]

  out = output_file_path(prefix: prefix, ext: "dump")
  StackProf.run(out: out, **opts) do
    run_enough_to_profile(n, &block)
  end

  gem_exe("stackprof", "--text", out)
  puts "Stackprof dump file:\n#{out}"

  # Dummy results to satisfy ./run_benchmarks.rb
  return_results([0], [1.0]) if ENV['RESULT_JSON_PATH']
end
