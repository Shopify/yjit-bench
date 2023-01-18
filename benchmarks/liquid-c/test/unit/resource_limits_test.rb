# frozen_string_literal: true

require "test_helper"

class ResourceLimitsTest < Minitest::Test
  def test_increment_render_score
    resource_limits = Liquid::ResourceLimits.new(render_score_limit: 5)
    resource_limits.increment_render_score(4)
    assert_raises(Liquid::MemoryError) do
      resource_limits.increment_render_score(2)
    end
    assert_equal(6, resource_limits.render_score)
  end

  def test_increment_assign_score
    resource_limits = Liquid::ResourceLimits.new(assign_score_limit: 5)
    resource_limits.increment_assign_score(5)
    assert_raises(Liquid::MemoryError) do
      resource_limits.increment_assign_score(1)
    end
    assert_equal(6, resource_limits.assign_score)
  end

  def test_increment_write_score
    resource_limits = Liquid::ResourceLimits.new(render_length_limit: 5)
    output = "a" * 10
    assert_raises(Liquid::MemoryError) do
      resource_limits.increment_write_score(output)
    end
  end

  def test_raise_limits_reached
    resource_limits = Liquid::ResourceLimits.new({})
    assert_raises(Liquid::MemoryError) do
      resource_limits.raise_limits_reached
    end
    assert(resource_limits.reached?)
  end

  def test_with_capture
    resource_limits = Liquid::ResourceLimits.new(assign_score_limit: 5)
    output = "foo"

    resource_limits.with_capture do
      resource_limits.increment_write_score(output)
    end

    assert_equal(3, resource_limits.assign_score)
  end
end
