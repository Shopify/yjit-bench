ENV['RAILS_ENV'] ||= 'production'
require "coverage"
Coverage.start
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

# Clear coverage before running
Coverage.result(stop: false, clear: true)
run_bench(app, visiting_routes)
result = Coverage.result

total_count = 0
top_20 = Array.new(20) { [0] }
result.each do |file, stats|
  stats.each_with_index do |count, i|
    if count
      total_count += count
      if count > top_20.last.first
        top_20.push([count, file, i + 1])
        top_20 = top_20.sort_by(&:first).reverse
        top_20.pop
      end
    end
  end
end

total_count = total_count.to_f

require "csv"
CSV do |csv|
  csv << %w{ count pct file line }
  top_20.each do |info|
    csv << ([info[0], sprintf("%0.2f", (info[0] / total_count))] + info.drop(1))
  end
end
