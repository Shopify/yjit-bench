require 'harness'

ENV['RAILS_ENV'] ||= 'production'

# Before we load ActiveRecord, let's make sure the
# database exists and is up to date.
# Note: db:migrate will create the DB if it doesn't exist,
# and this app's db/seeds.rb will delete and repopulate
# the database, so rows shouldn't accumulate.
Dir.chdir __dir__
use_gemfile extra_setup_cmd: "bin/rails db:migrate db:seed"

require_relative 'config/environment'

app = Rails.application

possible_routes = ['/posts', '/posts.json']
possible_routes.concat((1..100).map { |i| "/posts/#{i}"})

visit_count = 2000
rng = Random.new(0x1be52551fc152997)
visiting_routes = Array.new(visit_count) { possible_routes.sample(random: rng) }

c_calls = Hash.new { 0 }
c_loops = Hash.new { 0 }

TracePoint.new(:c_call) do |tp|
  method_name = "#{tp.defined_class}##{tp.method_id}"
  c_calls[method_name] += 1

  case tp.method_id
  when /(\A|_)each(_|\z)/, /(\A|_)map\!?\z/
    c_loops[method_name] += tp.self.size if tp.self.respond_to?(:size)
  when 'times'
    c_loops[method_name] += Integer(tp.self)
  end
end.enable

run_benchmark(10) do
  visiting_routes.each do |path|
    # The app mutates `env`, so we need to create one every time.
    env = Rack::MockRequest::env_for("http://localhost#{path}")
    response_array = app.call(env)
    unless response_array.first == 200
      raise "HTTP response is #{response_array.first} instead of 200. Is the benchmark app properly set up? See README.md."
    end
  end
end

puts "Top C loop method iterations:"
c_loops.sort_by(&:last).reverse_each do |method, count|
  puts '%8d %s' % [count, method]
end
puts

puts "Top 100 C method calls:"
c_calls.sort_by(&:last).reverse[0...100].each do |method, count|
  puts '%8d %s' % [count, method]
end
