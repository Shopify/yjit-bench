# frozen_string_literal: true

require "harness"

Dir.chdir(__dir__)
use_gemfile

require "rack"
#require "rack/builder"

# Start a server
app = Rack::Builder.new do
  #use Rack::CommonLogger
  map "/ok" do
    run lambda { |env| [200, {'content-type' => 'text/plain'}, ['OK']] }
  end
end

orig_env = Rack::MockRequest::env_for("http://localhost/ok")

run_benchmark(10) do
  10_000.times do
    # The app may mutate `env`, so we need to create one every time.
    env = orig_env.dup

    response = app.call(env)
    unless response[0] == 200
      raise "HTTP response is #{response.first.inspect} instead of 200. Is the benchmark app properly set up? See README.md."
    end
  end
end
