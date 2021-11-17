require 'harness'
Dir.chdir __dir__
use_gemfile

TEMPLATE_FILE = "simple_template.erb"

require "date"

IMPL = "erb"
#IMPL = "erubi"

require IMPL

EXPECTED_ERB_TEXT_SIZE = 1001
EXPECTED_ERUBI_TEXT_SIZE = 900 # Why different?
EXPECTED_ERB_SOURCE_SIZE = 174
EXPECTED_ERUBI_SOURCE_SIZE = 143

def generate_source(template_text)
  if IMPL == "erubi"
    src = Erubi::Engine.new(template_text).src
    raise "Wrong generated source size: #{src.size} instead of #{EXPECTED_ERUBI_SOURCE_SIZE}!" unless src.size == EXPECTED_ERUBI_SOURCE_SIZE
  else
    src = ERB.new(template_text).src
    raise "Wrong generated source size: #{src.size} instead of #{EXPECTED_ERB_SOURCE_SIZE}!" unless src.size == EXPECTED_ERB_SOURCE_SIZE
  end
  src
end

def check_result_size(result)
  if IMPL == "erubi"
    raise "Wrong text size: #{result.size} instead of #{EXPECTED_ERUBI_TEXT_SIZE}!" unless result.size == EXPECTED_ERUBI_TEXT_SIZE
  else
    raise "Wrong text size: #{result.size} instead of #{EXPECTED_ERB_TEXT_SIZE}!" unless result.size == EXPECTED_ERB_TEXT_SIZE
  end
end

def evaluate_erubi(view_stub)
  @template ||= File.read TEMPLATE_FILE
  src = Erubi::Engine.new(@template).src
  view_stub.instance_eval(src)
end

def erubi_source
  @template ||= File.read TEMPLATE_FILE
  Erubi::Engine.new(@template).src
end

template = File.read TEMPLATE_FILE
source = generate_source(template)

eval "def run_erb; #{source}; end"

run_benchmark(10) do
  500.times do
    #result = eval source
    result = run_erb
    #check_result_size(result)

  end
end
