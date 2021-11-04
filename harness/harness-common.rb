# Set up a Gemfile and a directory, install gems and do extra setup
def use_gemfile(in_dir: nil, extra_bundled_setup: nil)
  # Not finding an easy way to get the caller's __dir__ -- our own version shadows it.
  # Given the choice of caller or binding, caller is probably less disruptive to YJIT.
  in_dir ||= caller[-1].split(":")[0].split("/")[0..-2].join("/")

  Dir.chdir(in_dir) do
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
      raise "Couldn't set up benchmark in #{in_dir.inspect}!"
    end

    # Need to be in the appropriate directory
    require "bundler/setup"
  end
end
