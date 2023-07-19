require 'harness'

ENV['RAILS_ENV'] ||= 'production'
ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1' # Benchmarks don't really have 'production', so trash it at will.

# NOTE: added an srand to lib/tasks/fake_data to allow repeatable runs

Dir.chdir __dir__
#use_gemfile extra_setup_cmd: "cp db/benchmark_production.sqlite3 db/production.sqlite3"
use_gemfile extra_setup_cmd: "bin/rails db:drop db:create && sqlite3 db/production.sqlite3 < db/faked_bench_data.sql"

require_relative 'config/environment'

app = Rails.application

# TODO: touching a selection of 'random' routes first might better show megamorphism in call sites

# Do we need to distinguish between e.g. banned and non-banned users?

# Can turn off caching by logging in, or by setting a tag-filter cookie (see application_controller.rb)

ROUTE_GROUPS = [
  { num: 50, routes: ["/u"] }, # Users tree, showing order of invitation - lots of view logic
  { num: 50, routes: ["/active", "/newest", "/recent", "/hottest"] }, # Views of the stories by attributes
  { num: 50, routes: ["/rss"] }, # Less-common and less-interesting routes for variation
  #{ num: 50, routes: ["/top?length=1d", "/top?length=1w", "/top?length=1y"] }, # Top stories by time - failing w/ SQL err

  # Shouldn't add /404, because that returns status 404, not 200
  # /hidden /saved /upvoted   # These all required being logged in
]

#possible_routes += ['/posts', '/posts.json']
#possible_routes.concat((1..100).map { |i| "/posts/#{i}"})

rng = Random.new(0x1be52551fc152997)
visiting_routes = []
ROUTE_GROUPS.each do |group|
  group[:num].times do
    visiting_routes << group[:routes].sample(random: rng)
  end
end

if ENV['TRACK_AR_TIME']
  ar_total_duration = 0.0
  process_start_t = Time.now

  # Track sql.active_record events
  ActiveSupport::Notifications.subscribe "sql.active_record" do |name, started, finished, unique_id, data|
    duration = finished - started
    ar_total_duration += duration
  end

  at_exit do
    process_duration = Time.now - process_start_t
    ar_percent = ar_total_duration * 100.0 / process_duration
    puts "ActiveRecord time: #{ar_total_duration.round(2)}s (#{ar_percent.round(2)}%) PID: #{Process.pid}"
  end
end

run_benchmark(10) do
  visiting_routes.each do |path|
    # The app mutates `env` when reading body, so we should create one each iter just in case.
    env = Rack::MockRequest::env_for("https://localhost#{path}")
    env["HTTP_COOKIE"] = "tag_filters=NOCACHE" # turn off the file cache
    response_array = app.call(env)
    unless response_array.first == 200
      raise "HTTP status is #{response_array.first} instead of 200. Is the benchmark app properly set up? See README.md. / #{response_array.inspect}"
    end
  end
end
