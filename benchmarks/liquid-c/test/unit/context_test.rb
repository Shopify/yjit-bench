# frozen_string_literal: true

require "test_helper"
require "bigdecimal"

class ContextTest < Minitest::Test
  def test_evaluate_works_with_normal_values
    context = Liquid::Context.new

    ["abc", 123, false, 1.21, BigDecimal(42)].each do |value|
      assert_equal(value, context.evaluate(value))
    end

    assert_nil(context.evaluate(nil))
  end

  def test_evaluate_works_with_classes_that_have_an_evaluate_method
    class_with_evaluate = Class.new do
      def evaluate(_context)
        42
      end
    end

    assert_equal(42, Liquid::Context.new.evaluate(class_with_evaluate.new))
  end

  def test_evaluate_works_with_variable_lookup
    assert_equal(42, Liquid::Context.new({ "var" => 42 }).evaluate(Liquid::C::Expression.strict_parse("var")))
  end

  def test_evaluating_a_variable_entirely_within_c
    context = Liquid::Context.new({ "var" => 42 })
    lookup = Liquid::C::Expression.strict_parse("var")
    context.evaluate(lookup) # memoize vm_internal_new calls

    called_ruby_method_count = 0
    called_c_method_count = 0

    test_thread = Thread.current
    begin
      call_trace = TracePoint.trace(:call) do |t|
        unless t.self == TracePoint || t.self.is_a?(TracePoint) || Thread.current != test_thread
          called_ruby_method_count += 1
        end
      end

      c_call_trace = TracePoint.trace(:c_call) do |t|
        unless t.self == TracePoint || t.self.is_a?(TracePoint) || Thread.current != test_thread
          called_c_method_count += 1
        end
      end

      context.evaluate(lookup)
    ensure
      call_trace&.disable
      c_call_trace&.disable
    end

    assert_equal(0, called_ruby_method_count)
    assert_equal(1, called_c_method_count) # context.evaluate call
  end

  class TestDrop < Liquid::Drop
    def is_filtering # rubocop:disable Naming/PredicateName
      @context.send(:c_filtering?)
    end
  end

  def test_c_filtering_predicate
    context = Liquid::Context.new({ "test" => [TestDrop.new] })
    template = Liquid::Template.parse('{{ test[0].is_filtering }},{{ test | map: "is_filtering" }}')

    assert_equal("false,true", template.render!(context))
    assert_equal(false, context.send(:c_filtering?))
  end

  def test_strict_variables=
    context = Liquid::Context.new
    assert_equal(false, context.strict_variables)
    context.strict_variables = true
    assert_equal(true, context.strict_variables)
  end
end
