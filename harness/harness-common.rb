# Ensure the ruby in PATH is the ruby running this, so we can safely shell out to other commands
ruby_in_path = `ruby -e 'print RbConfig.ruby'`
unless ruby_in_path == RbConfig.ruby
  abort "The ruby running this script (#{RbConfig.ruby}) is not the first ruby in PATH (#{ruby_in_path})"
end

def run_cmd(*args)
  puts "Command: #{args.join(" ")}"
  system(*args)
end

# Set up a Gemfile, install gems and do extra setup
def use_gemfile(extra_setup_cmd: nil)
  # Benchmarks should normally set their current directory and then call this method.

  success = true
  success &&= run_cmd("bundle install")
  success &&= run_cmd(extra_setup_cmd) if extra_setup_cmd
  unless success
    raise "Couldn't set up benchmark in #{Dir.pwd.inspect}!"
  end

  # Need to be in the appropriate directory for this...
  require "bundler/setup"
end
