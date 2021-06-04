require 'harness'

require 'fileutils'

Dir.chdir(__dir__ + "/test-three-zero")

require 'bundler/inline'
gemfile do
    eval File.read("./Gemfile")
end

require "jekyll"

# Jekyll isn't designed to be used in quite this way, and doesn't seem to handle the same
# process cleaning and then building repeatedly in the obvious way. Rather than try to
# add new functionality to Jekyll, it makes more sense to carefully exclude the initial
# slow first build from the benchmarked time, and then only benchmark incremental runs
# where specific markdown files change.

# To do incremental builds, we take a markdown file and add a small, changing modification
# to the end. Like the original benchmark we append a number. Unlike the original, we keep the size
# the same for each incremental build.
orig_file = "./_posts/2009-05-15-edge-case-nested-and-mixed-lists.orig"
md_file = orig_file.sub(".orig", ".md")
md_size = File.size(md_file) + 1  # We add a newline and a number. This gets the offset after the newline
FileUtils.cp orig_file, md_file
File.open(md_file, "a") { |f| f.write("\n1") } # Append a newline and "1" to the markdown

# Make sure the first sometimes-slow run has completed.
Jekyll::Commands::Build.process({})

run_benchmark(20) do
    5.times do |i|
        # Replace the final number with 0, 1 or 2 for ensure the content changes.
        File.write("./_posts/2009-05-15-edge-case-nested-and-mixed-lists.md", (i % 3).to_s, md_size)
        Jekyll::Commands::Build.process({})
    end
end
