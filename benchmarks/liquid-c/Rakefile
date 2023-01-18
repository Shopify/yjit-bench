# frozen_string_literal: true

require "rake"
require "rake/testtask"
require "bundler/gem_tasks"
require "rake/extensiontask"
require "benchmark"
require "ruby_memcheck"

ENV["DEBUG"] ||= "true"

RubyMemcheck.config(binary_name: "liquid_c")

task default: [:test, :rubocop]

task test: ["test:unit", "test:integration:all"]

namespace :test do
  task valgrind: ["test:unit:valgrind", "test:integration:valgrind:all"]
end
