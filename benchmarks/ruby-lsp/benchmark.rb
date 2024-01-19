# frozen_string_literal: true

require_relative "../../harness/loader"

Dir.chdir(__dir__)
use_gemfile

# This benchmark checks the Ruby LSP indexing mechanism, which is used to keep track of all project declarations in
# every file of a project and its dependencies

require "ruby_lsp/internal"

path = File.expand_path("fixture.rb", __dir__)
index_path = RubyIndexer::IndexablePath.new(File.expand_path("../..", __dir__), path)
content = File.read(path)

run_benchmark(200) do
  RubyIndexer::Index.new.index_single(index_path, content)
end
