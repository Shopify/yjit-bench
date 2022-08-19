require 'harness'

Dir.chdir __dir__
use_gemfile
require 'psych'

test_yaml_files = Dir["#{__dir__}/yaml/*.yaml"].to_a

# Useful for testing only specific YAML files. I don't think we want
# a separate benchmark for each YAML file here.
if ENV['PSYCH_ONLY_LOAD']
  test_yaml_files.select! { |path| path[ENV['PSYCH_ONLY_LOAD']] }
end

if test_yaml_files.size < 1
  raise "Not loading any YAML files!"
end

test_yaml = test_yaml_files.map { |p| File.read(p) }

run_benchmark(20) do
  100.times do
    test_yaml.each do |yaml_content|
      y = Psych.load(yaml_content)
    end
  end
end
