# frozen_string_literal: true

task :rubocop do
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
end
