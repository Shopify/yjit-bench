# frozen_string_literal: true

require "harness"

Dir.chdir(__dir__)
use_gemfile

require "ruby_lsp/internal"

file_path = File.expand_path("fixture.rb", __dir__)
file_uri = "file://#{file_path}"

# These benchmarks are representative of the three main operations executed by the Ruby LSP server
run_benchmark(10) do
  # File parsing
  document = RubyLsp::Document.new(File.read(file_path))

  # Running RuboCop related requests
  RubyLsp::Requests::Diagnostics.new(file_uri, document).run

  # Running SyntaxTree visitor requests
  RubyLsp::Requests::SemanticHighlighting.new(
    document,
    encoder: RubyLsp::Requests::Support::SemanticTokenEncoder.new,
  ).run
end
