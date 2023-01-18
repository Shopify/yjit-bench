# encoding: utf-8
# frozen_string_literal: true

require "test_helper"

class TokenizerTest < Minitest::Test
  def test_tokenizer_nil
    tokenizer = new_tokenizer(nil)
    assert_nil(tokenizer.send(:shift))
  end

  def test_tokenize_strings
    assert_equal([" "], tokenize(" "))
    assert_equal(["hello world"], tokenize("hello world"))
  end

  def test_tokenize_variables
    assert_equal(["{{funk}}"], tokenize("{{funk}}"))
    assert_equal([" ", "{{funk}}", " "], tokenize(" {{funk}} "))
    assert_equal([" ", "{{funk}}", " ", "{{so}}", " ", "{{brother}}", " "], tokenize(" {{funk}} {{so}} {{brother}} "))
    assert_equal([" ", "{{  funk  }}", " "], tokenize(" {{  funk  }} "))

    # Doesn't strip whitespace
    assert_equal([" ", "  funk  ", " "], tokenize(" {{  funk  }} ", trimmed: true))
  end

  def test_tokenize_blocks
    assert_equal(["{%comment%}"], tokenize("{%comment%}"))
    assert_equal([" ", "{%comment%}", " "], tokenize(" {%comment%} "))

    assert_equal([" ", "{%comment%}", " ", "{%endcomment%}", " "], tokenize(" {%comment%} {%endcomment%} "))
    assert_equal(["  ", "{% comment %}", " ", "{% endcomment %}", " "], tokenize("  {% comment %} {% endcomment %} "))

    # Doesn't strip whitespace
    assert_equal([" ", "  comment  ", " "], tokenize(" {%  comment  %} ", trimmed: true))
  end

  def test_tokenize_for_liquid_tag
    source = "\nfunk\n\n  so | brother   \n"

    assert_equal(["", "funk", "", "  so | brother   "], tokenize(source, for_liquid_tag: true))

    # Strips whitespace
    assert_equal(["", "funk", "", "so | brother"], tokenize(source, for_liquid_tag: true, trimmed: true))
  end

  def test_invalid_tags
    assert_equal([""], tokenize("{%-%}", trimmed: true))
    assert_equal([""], tokenize("{{-}}", trimmed: true))
  end

  def test_utf8_encoded_source
    source = "auswählen"
    assert_equal(Encoding::UTF_8, source.encoding)
    output = tokenize(source)
    assert_equal([Encoding::UTF_8], output.map(&:encoding))
    assert_equal([source], output)
  end

  def test_utf8_compatible_source
    source = String.new("ascii", encoding: Encoding::ASCII)
    tokenizer = new_tokenizer(source)
    output = tokenizer.send(:shift)
    assert_equal(Encoding::UTF_8, output.encoding)
    assert_equal(source, output)
    assert_nil(tokenizer.send(:shift))
  end

  def test_non_utf8_compatible_source
    source = "üñicode".dup.force_encoding(Encoding::BINARY) # rubocop:disable Performance/UnfreezeString
    exc = assert_raises(Encoding::CompatibilityError) do
      Liquid::C::Tokenizer.new(source, 1, false)
    end
    assert_equal("non-UTF8 encoded source (ASCII-8BIT) not supported", exc.message)
  end

  def test_source_too_large
    too_large_source = "a" * 2**24
    max_length_source = too_large_source.chop

    # C safety check
    err = assert_raises(ArgumentError) do
      Liquid::C::Tokenizer.new(too_large_source, 1, false)
    end
    assert_match(/Source too large, max \d+ bytes/, err.message)

    # ruby patch fallback
    parse_context = Liquid::ParseContext.new
    liquid_c_tokenizer = parse_context.new_tokenizer(max_length_source)
    assert_instance_of(Liquid::C::Tokenizer, liquid_c_tokenizer)
    refute(parse_context.liquid_c_nodes_disabled?)

    parse_context = Liquid::ParseContext.new
    fallback_tokenizer = parse_context.new_tokenizer(too_large_source)
    assert_instance_of(Liquid::Tokenizer, fallback_tokenizer)
    assert_equal(true, parse_context.liquid_c_nodes_disabled?)
  end

  private

  def new_tokenizer(source, parse_context: Liquid::ParseContext.new)
    parse_context.new_tokenizer(source)
  end

  def tokenize(source, for_liquid_tag: false, trimmed: false)
    tokenizer = Liquid::C::Tokenizer.new(source, 1, for_liquid_tag)
    tokens = []
    while (t = trimmed ? tokenizer.send(:shift_trimmed) : tokenizer.send(:shift))
      tokens << t
    end
    tokens
  end
end
