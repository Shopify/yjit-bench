require 'harness'
Dir.chdir __dir__
use_gemfile

ENV['RAILS_ENV'] ||= 'production'
require_relative 'config/environment'

EXPECTED_TEXT_SIZE = 9369

app = Rails.application
fake_controller = FakeDiscourseController.new

run_benchmark(10) do
  100.times do
    out = FakeDiscourseController.render :topics_show, assigns: fake_controller.stub_assigns
  end
end
