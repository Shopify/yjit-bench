require_relative "../../harness/loader"

Dir.chdir __dir__
use_gemfile

require "graphql"

data = File.read "negotiate.gql"

run_benchmark(10) do
  10.times do |i|
    GraphQL.parse data
  end
end
