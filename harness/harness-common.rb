# Ensure the ruby in PATH is the ruby running this, so we can safely shell out to other commands
ruby_in_path = `ruby -e 'print RbConfig.ruby'`
unless ruby_in_path == RbConfig.ruby
  abort "The ruby running this script (#{RbConfig.ruby}) is not the first ruby in PATH (#{ruby_in_path})"
end

def run_cmd(*args)
  puts "Command: #{args.join(" ")}"
  system(*args)
end

def setup_cmds(c)
  c.each do |cmd|
    success = run_cmd(cmd)
    raise "Couldn't run setup command for benchmark in #{Dir.pwd.inspect}!" unless success
  end
end

# Set up a Gemfile, install gems and do extra setup
def use_gemfile(extra_setup_cmd: nil)
  # Benchmarks should normally set their current directory and then call this method.

  setup_cmds(["bundle install", extra_setup_cmd].compact)

  # Need to be in the appropriate directory for this...
  require "bundler/setup"
end
