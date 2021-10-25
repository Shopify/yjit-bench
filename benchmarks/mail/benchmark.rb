require "harness"

# Before we activate Bundler, make sure gems are installed.
Dir.chdir(__dir__) do
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

Dir.chdir __dir__
require "bundler/setup"
require "mail"

raw_email = File.binread("raw_email2.eml")

run_benchmark(10) do
  50.times do
    Mail.new(raw_email).to_s
  end
end
