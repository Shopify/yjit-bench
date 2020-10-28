module Lee
  # Similar to ::Matrix, but mutable, which it wasn't back in 2.5.7 which is what JRuby 9.2.13.0 supports.
  class Matrix
    def initialize(height, width, &block)
      @height = height
      @width = width
      size = width * height
      if block
        @array = Array.new(size, &block)
      else
        @array = Array.new(size, 0)
      end
    end

    def [](y, x)
      @array[index(y, x)]
    end

    def []=(y, x, value)
      @array[index(y, x)] = value
    end

    private

    def index(y, x)
      raise unless (0...@height).include?(y)
      raise unless (0...@width).include?(x)
      y * @width + x
    end
  end
end
