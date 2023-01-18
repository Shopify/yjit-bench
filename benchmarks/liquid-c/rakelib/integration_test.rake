# frozen_string_literal: true

namespace :test do
  integration_test_config = lambda do |t|
    t.libs << "lib"
    t.test_files = ["test/integration_test.rb"]
  end

  desc "run test suite with default parser"
  Rake::TestTask.new(integration: :compile, &integration_test_config)

  namespace :integration do
    define_env_integration_tests = lambda do |task_name|
      rake_task = Rake::Task[task_name]

      [
        [:lax, { "LIQUID_PARSER_MODE" => "lax" }],
        [:strict, { "LIQUID_PARSER_MODE" => "strict" }],
        [:without_vm, { "LIQUID_C_DISABLE_VM" => "true" }],
      ].each do |name, env_vars|
        task(name) do
          old_env_values = ENV.to_hash.slice(*env_vars.keys)
          begin
            env_vars.each { |key, value| ENV[key] = value }
            rake_task.invoke
          ensure
            old_env_values.each { |key, value| ENV[key] = value }
            rake_task.reenable
          end
        end
      end

      task(all: [:lax, :strict, :without_vm])
    end

    define_env_integration_tests.call("test:integration")

    RubyMemcheck::TestTask.new(valgrind: :compile, &integration_test_config)
    namespace :valgrind do
      define_env_integration_tests.call("test:integration:valgrind")
    end
  end
end
