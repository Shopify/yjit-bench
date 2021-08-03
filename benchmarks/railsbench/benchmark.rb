require 'harness'

# Before we activate Bundler, make sure gems are installed.
# And before we load ActiveRecord, let's make sure the
# database exists and is up to date.
# Note: db:migrate will create the DB if it doesn't exist,
# and this app's db/seeds.rb will delete and repopulate
# the database, so rows shouldn't accumulate.
Dir.chdir(__dir__) do
  chruby_stanza = ""
  if ENV['RUBY_ROOT']
    ruby_name = ENV['RUBY_ROOT'].split("/")[-1]
    chruby_stanza = "chruby #{ruby_name} && "
  end

  # Source Shopify-located chruby if it exists to make sure this works in Shopify Mac dev tools.
  # Use bash -l to propagate non-Shopify-style chruby config.
  success = system({ 'RAILS_ENV' => 'production' }, "/bin/bash -l -c '[ -f /opt/dev/dev.sh ] && . /opt/dev/dev.sh; #{chruby_stanza}bundle install && bundle exec bin/rails db:migrate db:seed'")
  unless success
    raise "Couldn't set up railsbench!"
  end
end

ENV['RAILS_ENV'] ||= 'production'
require_relative 'config/environment'

app = Rails.application

possible_routes = ['/posts', '/posts.json']
possible_routes.concat((1..100).map { |i| "/posts/#{i}"})

visit_count = 2000
rng = Random.new(0x1be52551fc152997)
visiting_routes = Array.new(visit_count) { possible_routes.sample(random: rng) }

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
