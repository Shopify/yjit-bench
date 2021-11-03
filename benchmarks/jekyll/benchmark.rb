require 'harness'

# Before we activate Bundler, make sure gems are installed.
Dir.chdir(__dir__ + "/test-three-zero") do
  chruby_stanza = ""
  if ENV['RUBY_ROOT']
    ruby_name = ENV['RUBY_ROOT'].split("/")[-1]
    chruby_stanza = "chruby && chruby #{ruby_name} && "
  end

  # Source Shopify-located chruby if it exists to make sure this works in Shopify Mac dev tools.
  # Use bash -l to propagate non-Shopify-style chruby config.
  cmd = "/bin/bash -l -c '[ -f /opt/dev/dev.sh ] && . /opt/dev/dev.sh; #{chruby_stanza}bundle install'"
  puts "Command: #{cmd}"
  success = system(cmd)
  unless success
    raise "Couldn't set up benchmark!"
  end
end

Dir.chdir(__dir__ + "/test-three-zero")

require 'bundler/setup'
require "jekyll"
require "fileutils"

# Jekyll isn't designed to be used in quite this way, and doesn't seem to handle the same
# process cleaning and then building repeatedly in the obvious way. Rather than try to
# add new functionality to Jekyll, it makes more sense to carefully exclude the initial
# slow first build from the benchmarked time, and then only benchmark incremental runs
# where specific markdown files change.

# To do incremental builds, we take a markdown file and add a small, changing modification
# to the end. Like the original benchmark we append a number. Unlike the original, we keep
# the file size the same for each incremental build.
md_file = "./_posts/2009-05-15-edge-case-nested-and-mixed-lists.md"
md_file_size = File.size(md_file)

# Make sure the first possibly-slow run has completed.
Jekyll::Commands::Build.process({})

# TODO: try updating a lot of different markdown files instead of just one and see how much it affects the build time?

run_benchmark(20) do
    5.times do |i|
        # Replace the final number with 0, 1 or 2 for ensure the content changes.
        File.write("./_posts/2009-05-15-edge-case-nested-and-mixed-lists.md", (i % 3).to_s, md_file_size - 2)
        Jekyll::Commands::Build.process({})
    end
end
