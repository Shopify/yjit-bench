# frozen_string_literal: true

require "test_helper"

class BlockTest < MiniTest::Test
  def test_no_allocation_of_trimmed_strings
    template = Liquid::Template.parse("{{ a -}}     {{- b }}")
    assert_equal(2, template.root.nodelist.size)

    template = Liquid::Template.parse("{{ a -}} foo {{- b }}")
    assert_equal(3, template.root.nodelist.size)
  end

  def test_raise_on_output_with_non_utf8_encoding
    output = String.new(encoding: Encoding::ASCII)
    template = Liquid::Template.parse("ascii text")
    exc = assert_raises(Encoding::CompatibilityError) do
      template.render!({}, output: output)
    end
    assert_equal("non-UTF8 encoded output (US-ASCII) not supported", exc.message)
  end

  def test_write_unicode_characters
    output = String.new(encoding: Encoding::UTF_8)
    template = Liquid::Template.parse("ü{{ unicode_char }}")
    assert_equal("üñ", template.render!({ "unicode_char" => "ñ" }, output: output))
  end

  def test_op_write_raw_w
    source = "a" * 2**8
    template = Liquid::Template.parse(source)
    assert_equal(source, template.render!)
  end

  def test_raise_for_non_c_parse_context
    parse_context = Liquid::ParseContext.new
    assert_raises(RuntimeError) do
      Liquid::C::BlockBody.new(parse_context)
    end
  end

  # Test for bug: https://github.com/Shopify/liquid-c/pull/120
  def test_bug_120_instrument
    calls = []
    Liquid::Usage.stub(:increment, ->(name) { calls << name }) do
      Liquid::Template.parse("{{ -.1 }}")
    end
    assert_equal(["liquid_c_negative_float_without_integer"], calls)

    calls = []
    Liquid::Usage.stub(:increment, ->(name) { calls << name }) do
      Liquid::Template.parse("{{ .1 }}")
    end
    assert_equal([], calls)
  end

  def test_disassemble_raw_w
    source = "a" * 2**8
    template = Liquid::Template.parse(source)
    block_body = template.root.body
    assert_equal(<<~ASM, block_body.disassemble)
      0x0000: write_raw_w("#{source}")
      0x0104: leave
    ASM
  end

  def test_disassemble
    source = <<~LIQUID
      raw
      {{- var | default: "none", allow_false: true -}}
      {%- increment counter -%}
    LIQUID
    template = Liquid::Template.parse(source, line_numbers: true)
    block_body = template.root.body
    increment_node = block_body.nodelist[2]
    assert_instance_of(Liquid::Increment, increment_node)
    assert_equal(<<~ASM, block_body.disassemble)
      0x0000: write_raw("raw")
      0x0005: render_variable_rescue(line_number: 2)
      0x0009: find_static_var("var")
      0x000c: push_const(\"none\")
      0x000f: push_const(\"allow_false\")
      0x0012: push_true
      0x0013: hash_new(1)
      0x0015: builtin_filter(name: :default, num_args: 3)
      0x0018: pop_write
      0x0019: write_node(#{increment_node.inspect})
      0x001c: leave
    ASM
  end

  def test_exception_renderer_exception
    original_error = Liquid::Error.new("original")
    handler_error = RuntimeError.new("exception handler error")
    context = Liquid::Context.new("raise_error" => ->(_ctx) { raise(original_error) })
    context.exception_renderer = lambda do |exc|
      if exc == original_error
        raise(handler_error)
      end
      exc
    end
    template = Liquid::Template.parse("{% assign x = raise_error %}")
    exc = assert_raises(RuntimeError) do
      template.render(context)
    end
    assert_equal(handler_error, exc)
  end

  StubFileSystem = Struct.new(:partials) do
    def read_template_file(template_path)
      partials.fetch(template_path)
    end
  end

  def test_include_partial_with_syntax_error
    old_file_system = Liquid::Template.file_system
    begin
      Liquid::Template.file_system = StubFileSystem.new({
        "invalid" => "{% foo %}",
        "valid" => '{% include "nested" %}',
        "nested" => "valid",
      })

      template = Liquid::Template.parse("{% include 'invalid' %},{% include 'valid' %}")
      assert_equal("Liquid syntax error: Unknown tag 'foo',valid", template.render)
    ensure
      Liquid::Template.file_system = old_file_system
    end
  end
end
