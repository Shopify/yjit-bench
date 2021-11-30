# Set up a Gemfile, install gems and do extra setup
def use_gemfile(extra_setup_cmd: nil)
  # Benchmarks should normally set their current directory and then call this method.

  chruby_stanza = ""
  if ENV['RUBY_ROOT']
    ruby_name = ENV['RUBY_ROOT'].split("/")[-1]
    chruby_stanza = "chruby && chruby #{ruby_name} && "
  end

  # Source Shopify-located chruby if it exists to make sure this works in Shopify Mac dev tools.
  # Use bash -l to propagate non-Shopify-style chruby config.
  add_shopify_env = if File.exists?("/opt/dev/dev.sh")
                      case ENV["SHELL"]
                      when /\/bash\Z/
                        ". /opt/dev/dev.sh;"
                      when /\/fish\Z/
                        ". /opt/dev/dev.fish;"
                      else
                        raise "Unknown shell #{ENV["SHELL"]}"
                      end
                    else
                      ""
                    end

  cmd = "#{ENV["SHELL"]} -l -c '#{add_shopify_env} #{chruby_stanza} bundle install'"

  if extra_setup_cmd
    cmd += " && #{extra_setup_cmd}"
  end
  puts "Command: #{cmd}"
  success = system(cmd)
  unless success
    raise "Couldn't set up benchmark in #{Dir.pwd.inspect}!"
  end

  # Need to be in the appropriate directory for this...
  require "bundler/setup"
end
