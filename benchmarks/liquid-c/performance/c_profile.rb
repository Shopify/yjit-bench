# frozen_string_literal: true

require "liquid"
require "liquid/c"
liquid_lib_dir = $LOAD_PATH.detect { |p| File.exist?(File.join(p, "liquid.rb")) }
require File.join(File.dirname(liquid_lib_dir), "performance/theme_runner")

TASK_NAMES = ["run", "compile", "render"]
task_name = ARGV.first || "run"
unless TASK_NAMES.include?(task_name)
  raise "Unsupported task '#{task_name}' (must be one of #{TASK_NAMES})"
end
task = ThemeRunner.new.method(task_name)

runner_id = fork do
  end_time = Time.now + 5.0
  task.call until Time.now >= end_time
end

profiler_pid = spawn("instruments -t 'Time Profiler' -p #{runner_id}")

Process.waitpid(runner_id)
Process.waitpid(profiler_pid)
