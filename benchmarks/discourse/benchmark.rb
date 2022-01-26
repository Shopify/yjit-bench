ENV["RAILS_ENV"] = "profile"
ENV["DISABLE_BOOTSNAP"] = "1" # There's a Ruby bug with loading ISEQs that Bootsnap+YJIT hits, as of Jan 2022

# GC tuning taken from Discourse's script/bench.rb
%w(
  DISCOURSE_DUMP_HEAP
  RUBY_GC_HEAP_INIT_SLOTS
  RUBY_GC_HEAP_FREE_SLOTS
  RUBY_GC_HEAP_GROWTH_FACTOR
  RUBY_GC_HEAP_GROWTH_MAX_SLOTS
  RUBY_GC_MALLOC_LIMIT
  RUBY_GC_OLDMALLOC_LIMIT
  RUBY_GC_MALLOC_LIMIT_MAX
  RUBY_GC_OLDMALLOC_LIMIT_MAX
  RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR
  RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR
  RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR
  RUBY_GLOBAL_METHOD_CACHE_SIZE
  LD_PRELOAD
).each { |var| ENV.delete(var) }
ENV['RUBY_GLOBAL_METHOD_CACHE_SIZE'] = '131072'
ENV['RUBY_GC_HEAP_GROWTH_MAX_SLOTS'] = '40000'
ENV['RUBY_GC_HEAP_INIT_SLOTS'] = '400000'
ENV['RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR'] = '1.5'

def run_cmd(c)
    puts c
    system(c) || raise("Error running command #{c.inspect} in dir #{Dir.pwd}!")
end

# Should exist at the same directory level as YJIT checkouts, yjit-bench, yjit-metrics, etc.
CLONE_ROOT = File.expand_path "#{__dir__}/../../.."

DISCOURSE_DIR = "#{CLONE_ROOT}/discourse"
DISCOURSE_GIT_URL = "https://github.com/noahgibbs/discourse.git"
DISCOURSE_GIT_TAG = "ruby_32_changes" # It'd be nice to use a real version, but none of them work with Ruby 3.2+
SETUP_DONE_FILE = File.expand_path "#{__dir__}/setup_done.txt"

def clone_and_set_tag(git_url, git_tag, dir)
    run_cmd("git clone #{git_url} #{dir}") unless File.exist?(dir)

    Dir.chdir(dir) do
        run_cmd("git clean -f && git checkout . && git fetch && git checkout #{git_tag}")
    end
end

clone_and_set_tag(DISCOURSE_GIT_URL, DISCOURSE_GIT_TAG, DISCOURSE_DIR)

# Pre-bundle-exec setup
unless File.exist?(SETUP_DONE_FILE)
    # We only have Ubuntu setup for this right now...
    if RUBY_PLATFORM["darwin"] || RUBY_PLATFORM["win"]
        raise "Discourse bench isn't set up and we're on Mac or Windows! Dying!"
    end

    cmds = [
        "sudo apt-get -y install libxslt1-dev libcurl4-openssl-dev libksba8 libksba-dev libreadline-dev libssl-dev zlib1g-dev libsnappy-dev",
        "sudo apt-get -y install libsqlite3-dev sqlite3",
        "sudo apt-get -y install postgresql-server-dev-all postgresql-contrib libpq-dev libtool",

        "wget https://raw.githubusercontent.com/discourse/discourse_docker/master/image/base/install-imagemagick",
        "chmod +x install-imagemagick",
        "sudo ./install-imagemagick",

        "sudo apt-get -y install advancecomp gifsicle jpegoptim libjpeg-progs optipng pngcrush pngquant",
        "sudo apt-get install -y jhead",
        "sudo apt-get install -y brotli",

        "sudo wget -qO /usr/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64",
        "sudo chmod +x /usr/bin/mailhog",

        "curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -",
        "sudo apt-get -y install nodejs",
        "sudo npm install -g svgo",
        "sudo npm install -g yarn",

        "sudo apt-get -y install apache2-utils", # For ApacheBench
    ]

    # These shouldn't be setup_cmds, because we need to *not* require the harness yet
    cmds.each { |c| run_cmd c }

    require "fileutils"
    FileUtils.touch SETUP_DONE_FILE
end

Dir.chdir DISCOURSE_DIR

# This is horrible and I'm a bad person for doing it. FORCE_BUNDLER_VERSION is yjit-metrics-specific.
# Unfortunately, if the wrong version of Bundler gets activated first, we're completely screwed.
# And Bundler has a "fun" tendency to propagate its chosen version via env vars, etc.
# So: use only a single Bundler version, everywhere. Do not call up that which you cannot put down.
bundle_cmd = "bundle"
if ENV["FORCE_BUNDLER_VERSION"]
    bundle_cmd = "bundle _#{ENV["FORCE_BUNDLER_VERSION"]}_"
    gem "bundler", ENV["FORCE_BUNDLER_VERSION"]
end

# This isn't going to honor the current FORCE_BUNDLER setting, which it would if run via setup_cmds
#run_cmd("#{bundle_cmd} update sanitize")

# use_gemfile is going to do this... But we need to make sure we have all the gems installed before
# requiring bundler/setup.
run_cmd("#{bundle_cmd} install")

# This whole thing breaks the normal use_gemfile flow. We're doing it manually here. Ugh.
#use_gemfile

# This should make sure we get the right version of e.g. json, so requiring the harness
# becomes okay. But we needed to do the Gemfile surgery first to get correct versions. And we
# needed to do the raw OS install first so that gems could build.
require "bundler/setup"

# Require harness only *after* versions of common gems like json are set via use_gemfile
require 'harness'

setup_cmds([
    "bin/rails db:migrate",
    "bundle exec ruby script/profile_db_generator.rb",
    #"bundle exec rake assets:precompile",   # We can skip this one for this benchmark
])

puts "Getting api key"
api_key = `bundle exec rake api_key:create_master[bench]`.split("\n")[-1]
headers = { 'Api-Key' => api_key,
          'Api-Username' => "admin1" }

# Done all that? Okay, now it's time to load up the Rails app.
require "#{DISCOURSE_DIR}/config/environment"

app = Rails.application
RateLimiter.disable

# TODO: something more interesting with routes
routes = [ "/categories" ]

run_benchmark(10) do
    env = Rack::MockRequest::env_for("http://localhost#{routes[0]}", headers: headers)
    response_array = app.call(env)
    unless response_array[0] == 200
        raise "HTTP response is #{response_array.first} instead of 200. Is the benchmark app properly set up? See README.md."
    end
end
