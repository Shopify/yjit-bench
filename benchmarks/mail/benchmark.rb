require "bundler/inline"
require "harness"

gemfile do
  source "https://rubygems.org"
  gem "mail", "2.7.1"
end

require "mail"

raw_email = File.binread("#{__dir__}/raw_email2.eml")

run_benchmark(10) do
  50.times do
    Mail.new(raw_email).to_s
  end
end
