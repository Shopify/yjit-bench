# A simple factory generating valid moves for board sizes starting 9
module Rubykon
  module StoneFactory
    extend self

    DEFAULT_X     = 5
    DEFAULT_Y     = 9
    DEFAULT_COLOR = :black

    def build(options = {})
      x     = options.fetch(:x,     DEFAULT_X)
      y     = options.fetch(:y,     DEFAULT_Y)
      color = options.fetch(:color, DEFAULT_COLOR)
      [x, y, color]
    end

    def pass(color = DEFAULT_COLOR)
      build x: nil, y: nil, color: color
    end
  end
end
