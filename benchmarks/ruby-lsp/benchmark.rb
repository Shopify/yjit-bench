# frozen_string_literal: true

require_relative "../../harness/loader"

Dir.chdir(__dir__)
use_gemfile

require "ruby_lsp/internal"

file_path = File.expand_path("fixture.rb", __dir__)
file_uri = "file://#{file_path}"
content = File.read(file_path)

rc_last = nil
hl_last = nil

# These benchmarks are representative of the three main operations executed by the Ruby LSP server
run_benchmark(200) do
  # File parsing
  document = RubyLsp::Document.new(content)

  # Running RuboCop related requests
  rc = RubyLsp::Requests::Diagnostics.new(file_uri, document).run
  rc_last = rc.size

  # Running SyntaxTree visitor requests
  hl = RubyLsp::Requests::SemanticHighlighting.new(
    document,
    encoder: RubyLsp::Requests::Support::SemanticTokenEncoder.new,
  ).run
  hl_last = hl.data.size
end

raise("ruby-lsp benchmark: the RuboCop diagnostics test is returning the wrong answer!") if rc_last != 34
raise("ruby-lsp benchmark: the Semantic Highlighting test is returning the wrong answer!") if hl_last != 1160
