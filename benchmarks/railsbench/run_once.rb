ENV['RAILS_ENV'] ||= 'production'
require_relative 'config/environment'

app = Rails.application

possible_routes = ['/posts', '/posts.json']
possible_routes.concat((1..100).map { |i| "/posts/#{i}"})

visit_count = 2000
rng = Random.new(0x1be52551fc152997)
visiting_routes = Array.new(visit_count) { possible_routes.sample(random: rng) }

puts("***RUNNING BENCHMARK***")

# Don't want stats for loading the benchmark.
YJIT.reset_stats! if defined?(YJIT.reset_stats!)

visiting_routes.each do |path|
  # The app mutates `env`, so we need to create one every time.
  env = Rack::MockRequest::env_for("http://localhost#{path}")
  response_array = app.call(env)
  unless response_array.first == 200
    p response_array
    raise "HTTP response is #{response_array.first} instead of 200. Is the benchmark app properly set up? See README.md."
  end
end
