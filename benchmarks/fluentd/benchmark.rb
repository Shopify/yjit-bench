# frozen_string_literal: true

require 'harness'

Dir.chdir(__dir__)
use_gemfile

require 'fluent/engine'
require 'fluent/parser'

# Prepare a fixture
ltsv = 1000000.times.map do
  "time:2022-08-07 07:38:31,842	module:main.py	level:DEBUG	message:No kernel command line url found.\n"
end.join

# Prepare an LTSV parser
parser = Fluent::Plugin::LabeledTSVParser.new
parser.configure(Fluent::Config::Element.new('parse', '', {}, []))

# Benchmark the `<parse>@type ltsv</parse>` use case
run_benchmark(10) do
  parser.parse(ltsv) {}
end
