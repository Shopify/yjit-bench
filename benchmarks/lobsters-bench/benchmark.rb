require 'harness'

ENV['RAILS_ENV'] ||= 'production'
ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1' # Benchmarks don't really have 'production', so trash it at will.

# TODO: how to handle repeated runs and re-seeding without full drop-and-recreate?

# NOTE: added an srand to lib/tasks/fake_data to allow repeatable runs

Dir.chdir __dir__
use_gemfile extra_setup_cmd: "bin/rails benchmark_fake_data"

require_relative 'config/environment'

app = Rails.application

# TODO: touching a selection of 'random' routes first might better show megamorphism in call sites

# Note: for now possible_routes is sampled uniformly for simplicity.

possible_routes = []
possible_routes += []
#possible_routes += ['/posts', '/posts.json']
#possible_routes.concat((1..100).map { |i| "/posts/#{i}"})

visit_count = 2000
rng = Random.new(0x1be52551fc152997)
# for now possible_routes is sampled uniformly for simplicity.
visiting_routes = Array.new(visit_count) { possible_routes.sample(random: rng) }

run_benchmark(10) do
  visiting_routes.each do |path|
    # The app mutates `env` when reading body, so we should create one every time.
    env = Rack::MockRequest::env_for("http://localhost#{path}")
    response_array = app.call(env)
    unless response_array.first == 200
      raise "HTTP response is #{response_array.first} instead of 200. Is the benchmark app properly set up? See README.md."
    end
  end
end
