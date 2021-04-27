ENV['RAILS_ENV'] ||= 'production'
require_relative 'config/environment'

top_n = (ENV['TOP'] || 20).to_i
app = Rails.application

possible_routes = ['/posts', '/posts.json']
possible_routes.concat((1..100).map { |i| "/posts/#{i}"})

visit_count = 2000
rng = Random.new(0x1be52551fc152997)
visiting_routes = Array.new(visit_count) { possible_routes.sample(random: rng) }

def run_bench(app, visiting_routes)
  visiting_routes.each do |path|
    # The app mutates `env`, so we need to create one every time.
    env = Rack::MockRequest::env_for("http://localhost#{path}")
    response_array = app.call(env)
    unless response_array.first == 200
      p response_array
      raise "HTTP response is #{response_array.first} instead of 200. Is the benchmark app properly set up? See README.md."
    end
  end
end

# Warm the application
run_bench(app, visiting_routes)

# Record calls
events = Hash.new(0)

tp = TracePoint.new(:c_call, :call) do |event|
  events[[event.event, event.defined_class, event.method_id, event.path, event.lineno]] += 1
end

tp.enable
run_bench(app, visiting_routes)
tp.disable

total = events.values.inject(:+).to_f

require "csv"
CSV do |csv|
  csv << %w{ count pct type class method file line }
  events.sort_by(&:last).reverse.first(top_n).each do |event_info, count|
    csv << ([count, sprintf("%0.2f", (count / total) * 100)] + event_info)
  end
end
