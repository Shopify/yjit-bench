# frozen_string_literal: true

namespace :test do
  unit_test_config = lambda do |t|
    t.libs << "lib" << "test"
    t.test_files = FileList["test/unit/**/*_test.rb"]
  end

  Rake::TestTask.new(unit: :compile, &unit_test_config)

  namespace :unit do
    RubyMemcheck::TestTask.new(valgrind: :compile, &unit_test_config)
  end
end
