# frozen_string_literal: true

require "test_helper"

class ExpressionTest < MiniTest::Test
  def test_constant_literals
    assert_equal(true, Liquid::C::Expression.strict_parse("true"))
    assert_equal(false, Liquid::C::Expression.strict_parse("false"))
    assert_nil(Liquid::C::Expression.strict_parse("nil"))
    assert_nil(Liquid::C::Expression.strict_parse("null"))

    empty = Liquid::C::Expression.strict_parse("empty")
    assert_equal("", empty)
    assert_same(empty, Liquid::C::Expression.strict_parse("blank"))
  end

  def test_push_literals
    assert_nil(compile_and_eval("nil"))
    assert_equal(true, compile_and_eval("true"))
    assert_equal(false, compile_and_eval("false"))
  end

  def test_constant_integer
    assert_equal(42, Liquid::C::Expression.strict_parse("42"))
  end

  def test_push_int8
    assert_equal(127, compile_and_eval("127"))
    assert_equal(-128, compile_and_eval("-128"))
  end

  def test_push_int16
    assert_equal(128, compile_and_eval("128"))
    assert_equal(-129, compile_and_eval("-129"))
    assert_equal(32767, compile_and_eval("32767"))
    assert_equal(-32768, compile_and_eval("-32768"))
  end

  def test_push_large_fixnum
    assert_equal(32768, compile_and_eval("32768"))
    assert_equal(-2147483648, compile_and_eval("-2147483648"))
    assert_equal(2147483648, compile_and_eval("2147483648"))
    assert_equal(4611686018427387903, compile_and_eval("4611686018427387903"))
  end

  def test_push_big_int
    num = 1 << 128
    assert_equal(num, compile_and_eval(num.to_s))
  end

  def test_float
    assert_equal(123.4, Liquid::C::Expression.strict_parse("123.4"))
    assert_equal(-1.5, compile_and_eval("-1.5"))
  end

  def test_string
    assert_equal("hello", Liquid::C::Expression.strict_parse('"hello"'))
    assert_equal("world", compile_and_eval("'world'"))
  end

  def test_find_static_variable
    context = Liquid::Context.new({ "x" => 123 })
    expr = Liquid::C::Expression.strict_parse("x")

    assert_instance_of(Liquid::C::Expression, expr)
    assert_equal(123, context.evaluate(expr))
  end

  def test_find_dynamic_variable
    context = Liquid::Context.new({ "x" => "y", "y" => 42 })
    expr = Liquid::C::Expression.strict_parse("[x]")
    assert_equal(42, context.evaluate(expr))
  end

  def test_find_missing_variable
    context = Liquid::Context.new({})
    expr = Liquid::C::Expression.strict_parse("missing")

    assert_nil(context.evaluate(expr))

    context.strict_variables = true

    assert_raises(Liquid::UndefinedVariable) do
      context.evaluate(expr)
    end
  end

  def test_lookup_const_key
    context = Liquid::Context.new({ "obj" => { "prop" => "some value" } })

    expr = Liquid::C::Expression.strict_parse("obj.prop")
    assert_equal("some value", context.evaluate(expr))

    expr = Liquid::C::Expression.strict_parse('obj["prop"]')
    assert_equal("some value", context.evaluate(expr))
  end

  def test_lookup_variable_key
    context = Liquid::Context.new({ "field_name" => "prop", "obj" => { "prop" => "another value" } })
    expr = Liquid::C::Expression.strict_parse("obj[field_name]")
    assert_equal("another value", context.evaluate(expr))
  end

  def test_lookup_command
    context = Liquid::Context.new({ "ary" => ["a", "b", "c"] })
    assert_equal(3, context.evaluate(Liquid::C::Expression.strict_parse("ary.size")))
    assert_equal("a", context.evaluate(Liquid::C::Expression.strict_parse("ary.first")))
    assert_equal("c", context.evaluate(Liquid::C::Expression.strict_parse("ary.last")))
  end

  def test_lookup_missing_key
    context = Liquid::Context.new({ "obj" => {} })
    expr = Liquid::C::Expression.strict_parse("obj.missing")

    assert_nil(context.evaluate(expr))

    context.strict_variables = true

    assert_raises(Liquid::UndefinedVariable) do
      context.evaluate(expr)
    end
  end

  def test_lookup_on_var_with_literal_name
    context = Liquid::Context.new({ "blank" => { "x" => "result" } })

    assert_equal("result", context.evaluate(Liquid::C::Expression.strict_parse("blank.x")))
    assert_equal("result", context.evaluate(Liquid::C::Expression.strict_parse('blank["x"]')))
  end

  def test_const_range
    assert_equal((1..2), Liquid::C::Expression.strict_parse("(1..2)"))
  end

  def test_dynamic_range
    context = Liquid::Context.new({ "var" => 42 })
    expr = Liquid::C::Expression.strict_parse("(1..var)")
    assert_instance_of(Liquid::C::Expression, expr)
    assert_equal((1..42), context.evaluate(expr))
  end

  def test_disassemble
    expression = Liquid::C::Expression.strict_parse("foo.bar[123]")
    assert_equal(<<~ASM, expression.disassemble)
      0x0000: find_static_var("foo")
      0x0003: lookup_const_key("bar")
      0x0006: push_int8(123)
      0x0008: lookup_key
      0x0009: leave
    ASM
  end

  def test_disassemble_int16
    assert_equal(<<~ASM, Liquid::C::Expression.strict_parse("[12345]").disassemble)
      0x0000: push_int16(12345)
      0x0003: find_var
      0x0004: leave
    ASM
  end

  def test_disable_c_nodes
    context = Liquid::Context.new({ "x" => 123, "y" => { 123 => 42 } })

    expr = Liquid::ParseContext.new.parse_expression("x")
    assert_instance_of(Liquid::C::Expression, expr)
    assert_equal(123, context.evaluate(expr))

    expr = Liquid::ParseContext.new(disable_liquid_c_nodes: true).parse_expression("x")
    assert_instance_of(Liquid::VariableLookup, expr)
    assert_equal(123, context.evaluate(expr))

    expr = Liquid::ParseContext.new(disable_liquid_c_nodes: true).parse_expression("y[x]")
    assert_instance_of(Liquid::VariableLookup, expr)
    assert_instance_of(Liquid::VariableLookup, expr.lookups.first)
    assert_equal(42, context.evaluate(expr))
  end

  private

  class ReturnKeyDrop < Liquid::Drop
    def liquid_method_missing(key)
      key
    end
  end

  def compile_and_eval(source)
    context = Liquid::Context.new({ "ret_key" => ReturnKeyDrop.new })
    expr = Liquid::C::Expression.strict_parse("ret_key[#{source}]")
    context.evaluate(expr)
  end
end
