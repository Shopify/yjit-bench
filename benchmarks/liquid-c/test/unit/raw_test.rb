# frozen_string_literal: true

require "test_helper"

class RawTest < Minitest::Test
  class RawWrapper < Liquid::Raw
    def render_to_output_buffer(_context, output)
      output << "<"
      super
      output << ">"
    end
  end
  Liquid::Template.register_tag("raw_wrapper", RawWrapper)

  def test_derived_class
    output = Liquid::Template.parse("{% raw_wrapper %}body{% endraw_wrapper %}").render!
    assert_equal("<body>", output)
  end
end
