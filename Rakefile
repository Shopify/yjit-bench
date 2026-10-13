# frozen_string_literal: true

require 'rake/testtask'

desc 'Run all tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  test_files = FileList['test/**/*_test.rb']
  # rmagick segfaults on truffleruby 25.0.0, and the graph group with rmagick is not installed on Windows
  if RUBY_ENGINE == 'truffleruby' || Gem.win_platform?
    test_files -= ['test/graph_renderer_test.rb']
  end
  t.test_files = test_files
  t.verbose = true
  t.warning = true
end

task default: :test
