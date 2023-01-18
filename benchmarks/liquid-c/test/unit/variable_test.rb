# encoding: utf-8
# frozen_string_literal: true

require "test_helper"

class VariableTest < Minitest::Test
  def test_variable_parse
    assert_equal("world", variable_strict_parse("hello").render!({ "hello" => "world" }))
    assert_equal("world", variable_strict_parse('"world"').render!)
    assert_equal("answer", variable_strict_parse('hello["world"]').render!({ "hello" => { "world" => "answer" } }))
    assert_equal("answer", variable_strict_parse("question?").render!({ "question?" => "answer" }))
    assert_equal("value", variable_strict_parse("[meta]").render!({ "meta" => "key", "key" => "value" }))
    assert_equal("result", variable_strict_parse("a-b").render!({ "a-b" => "result" }))
    assert_equal("result", variable_strict_parse("a-2").render!({ "a-2" => "result" }))
  end

  def test_strictness
    assert_raises(Liquid::SyntaxError) { variable_strict_parse(' hello["world\']" ') }
    assert_raises(Liquid::SyntaxError) { variable_strict_parse(" -..") }
    assert_raises(Liquid::SyntaxError) { variable_strict_parse("question?mark") }
    assert_raises(Liquid::SyntaxError) { variable_strict_parse("123.foo") }
    assert_raises(Liquid::SyntaxError) { variable_strict_parse(" | nothing") }

    ["a -b", "a- b", "a - b"].each do |var|
      assert_raises(Liquid::SyntaxError) { variable_strict_parse(var) }
    end
  end

  def test_literals
    assert_equal("", variable_strict_parse("").render!)
    assert_equal("true", variable_strict_parse("true").render!)
    assert_equal("", variable_strict_parse("nil").render!)
    assert_equal("123.4", variable_strict_parse("123.4").render!)

    assert_equal("blank_value", variable_strict_parse("[blank]").render!({ "" => "blank_value" }))
    assert_equal("result", variable_strict_parse("[true][blank]").render!({ true => { "" => "result" } }))
    assert_equal("result", variable_strict_parse('x["size"]').render!({ "x" => { "size" => "result" } }))
    assert_equal("result", variable_strict_parse("blank.x").render!({ "blank" => { "x" => "result" } }))
    assert_equal("result", variable_strict_parse('blank["x"]').render!({ "blank" => { "x" => "result" } }))
  end

  module InspectCallFilters
    def filter1(input, *args)
      inspect_call(__method__, input, args)
    end

    def filter2(input, *args)
      inspect_call(__method__, input, args)
    end

    private

    def inspect_call(filter_name, input, args)
      "{ filter: #{filter_name.inspect}, input: #{input.inspect}, args: #{args.inspect} }"
    end
  end

  def test_variable_filter
    context = { "name" => "Bob" }

    filter1_output = variable_strict_parse("name | filter1").render!(context, filters: [InspectCallFilters])
    assert_equal('{ filter: :filter1, input: "Bob", args: [] }', filter1_output)

    filter2_output = variable_strict_parse("name | filter1 | filter2").render!(context, filters: [InspectCallFilters])
    assert_equal("{ filter: :filter2, input: #{filter1_output.inspect}, args: [] }", filter2_output)
  end

  def test_variable_filter_args
    context = { "name" => "Bob", "abc" => "xyz" }
    render_opts = { filters: [InspectCallFilters] }

    filter1_output = variable_strict_parse("name | filter1: abc").render!(context, render_opts)
    assert_equal('{ filter: :filter1, input: "Bob", args: ["xyz"] }', filter1_output)

    filter2_output = variable_strict_parse("name | filter1: abc | filter2: abc").render!(context, render_opts)
    assert_equal("{ filter: :filter2, input: #{filter1_output.inspect}, args: [\"xyz\"] }", filter2_output)

    context = { "name" => "Bob", "a" => 1, "c" => 3, "e" => 5 }

    output = variable_strict_parse("name | filter1 : a , b : c , d : e").render!(context, render_opts)
    assert_equal('{ filter: :filter1, input: "Bob", args: [1, {"b"=>3, "d"=>5}] }', output)

    assert_raises(Liquid::SyntaxError) do
      variable_strict_parse("name | filter : a : b : c : d : e")
    end
  end

  def test_unicode_strings
    string_content = "å߀êùｉｄｈｔлｓԁѵ߀ｒáƙìｓｔɦｅƅêｓｔｐｃｍáѕｔｅｒｒãｃêｃհèｒｒ"
    assert_equal(string_content, variable_strict_parse("\"#{string_content}\"").render!)
  end

  def test_broken_unicode_errors
    err = assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse("test {{ \xC2\xA0 test }}", error_mode: :strict)
    end
    assert(err.message)
  end

  def test_callbacks
    variable_fallbacks = 0

    callbacks = {
      variable_fallback: lambda { variable_fallbacks += 1 },
    }

    Liquid::Template.parse("{{abc}}", error_mode: :lax, stats_callbacks: callbacks)
    assert_equal(0, variable_fallbacks)

    Liquid::Template.parse("{{@!#}}", error_mode: :lax, stats_callbacks: callbacks)
    assert_equal(1, variable_fallbacks)
  end

  def test_write_string
    output = Liquid::Template.parse("{{ str }}").render({ "str" => "foo" })
    assert_equal("foo", output)
  end

  def test_write_fixnum
    output = Liquid::Template.parse("{{ num }}").render({ "num" => 123456 })
    assert_equal("123456", output)
  end

  def test_write_array
    output = Liquid::Template.parse("{{ ary }}").render({ "ary" => ["foo", 123, ["nested", "ary"], nil, 0.5] })
    assert_equal("foo123nestedary0.5", output)
  end

  def test_write_nil
    output = Liquid::Template.parse("{{ obj }}").render({ "obj" => nil })
    assert_equal("", output)
  end

  class StringConvertible
    def initialize(as_string)
      @as_string = as_string
    end

    def to_s
      @as_string
    end

    def to_liquid
      self
    end
  end

  def test_write_to_s_convertible_object
    output = Liquid::Template.parse("{{ obj }}").render!({ "obj" => StringConvertible.new("foo") })
    assert_equal("foo", output)
  end

  def test_write_object_with_broken_to_s
    template = Liquid::Template.parse("{{ obj }}")
    exc = assert_raises(TypeError) do
      template.render!({ "obj" => StringConvertible.new(123) })
    end
    assert_equal(
      "VariableTest::StringConvertible#to_s returned a non-String convertible value of type Integer",
      exc.message
    )
  end

  class DerivedString < String
    def to_s
      self
    end
  end

  def test_write_derived_string
    output = Liquid::Template.parse("{{ obj }}").render!({ "obj" => DerivedString.new("bar") })
    assert_equal("bar", output)
  end

  def test_filter_without_args
    output = Liquid::Template.parse("{{ var | upcase }}").render({ "var" => "Hello" })
    assert_equal("HELLO", output)
  end

  def test_filter_with_const_arg
    output = Liquid::Template.parse("{{ x | plus: 2 }}").render({ "x" => 3 })
    assert_equal("5", output)
  end

  def test_filter_with_variable_arg
    output = Liquid::Template.parse("{{ x | plus: y }}").render({ "x" => 10, "y" => 123 })
    assert_equal("133", output)
  end

  def test_filter_with_variable_arg_after_const_arg
    output = Liquid::Template.parse("{{ ary | slice: 1, 2 }}").render({ "ary" => [1, 2, 3, 4] })
    assert_equal("23", output)
  end

  def test_filter_with_const_keyword_arg
    output = Liquid::Template.parse("{{ value | default: 'None' }}").render({ "value" => false })
    assert_equal("None", output)

    output = Liquid::Template.parse("{{ value | default: 'None', allow_false: true }}").render({ "value" => false })
    assert_equal("false", output)
  end

  def test_filter_with_variable_keyword_arg
    template = Liquid::Template.parse("{{ value | default: 'None', allow_false: false_allowed }}")

    assert_equal("None", template.render({ "value" => false, "false_allowed" => false }))
    assert_equal("false", template.render({ "value" => false, "false_allowed" => true }))
  end

  def test_filter_error
    output = Liquid::Template.parse("before ({{ ary | concat: 2 }}) after").render({ "ary" => [1] })
    assert_equal("before (Liquid error: concat filter requires an array argument) after", output)
  end

  def test_render_variable_object
    variable = Liquid::Variable.new("ary | concat: ary2", Liquid::ParseContext.new)
    assert_instance_of(Liquid::C::VariableExpression, variable.name)

    context = Liquid::Context.new("ary" => [1], "ary2" => [2])
    assert_equal([1, 2], variable.render(context))

    context["ary2"] = 2
    exc = assert_raises(Liquid::ArgumentError) do
      variable.render(context)
    end
    assert_equal("Liquid error: concat filter requires an array argument", exc.message)
  end

  def test_filter_argument_error_translation
    variable = Liquid::Variable.new("'some words' | split", Liquid::ParseContext.new)
    context = Liquid::Context.new
    exc = assert_raises(Liquid::ArgumentError) { variable.render(context) }
    assert_equal("Liquid error: wrong number of arguments (given 1, expected 2)", exc.message)
  end

  class IntegerDrop < Liquid::Drop
    def initialize(value)
      super()
      @value = value.to_i
    end

    def to_liquid_value
      @value
    end
  end

  def test_to_liquid_value_on_variable_lookup
    context = {
      "number" => IntegerDrop.new("1"),
      "list" => [1, 2, 3, 4, 5],
    }

    output = variable_strict_parse("list[number]").render!(context)
    assert_equal("2", output)
  end

  private

  def variable_strict_parse(markup)
    Liquid::Template.parse("{{#{markup}}}", error_mode: :strict)
  end
end
