require 'harness'

Dir.chdir(__dir__ + "/test-three-zero")

status = system("bundle exec jekyll clean")
raise "Error trying to run 'jekyll clean'!" unless status

require 'bundler/inline'
gemfile do
	eval File.read("./Gemfile")
end

require "jekyll"

# TODO: increase to 20
run_benchmark(1) do
  Jekyll::Commands::Build.process({})
end
