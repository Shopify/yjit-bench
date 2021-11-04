# Set up a Gemfile, install gems and do extra setup
def use_gemfile(extra_bundled_setup: nil)
  # Benchmarks should normally set their current directory and then call this method.

  chruby_stanza = ""
  if ENV['RUBY_ROOT']
    ruby_name = ENV['RUBY_ROOT'].split("/")[-1]
    chruby_stanza = "chruby && chruby #{ruby_name} && "
  end

  # Source Shopify-located chruby if it exists to make sure this works in Shopify Mac dev tools.
  # Use bash -l to propagate non-Shopify-style chruby config.
  cmd = "/bin/bash -l -c '[ -f /opt/dev/dev.sh ] && . /opt/dev/dev.sh; #{chruby_stanza}bundle install'"
  if extra_bundled_setup
    cmd += " && #{extra_bundled_setup}"
  end
  puts "Command: #{cmd}"
  success = system(cmd)
  unless success
    raise "Couldn't set up benchmark in #{Dir.pwd.inspect}!"
  end

  # Need to be in the appropriate directory for this...
  require "bundler/setup"
end
