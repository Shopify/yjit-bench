require 'harness'

class TheClass
  def initialize
    @v0 = 1
    @v1 = 2
    @v3 = 3
    @levar = 1
  end

  def set_value_loop(obj)
    # 1M
    i = 0
    while i < 1000000
      # 10 times to de-emphasize loop overhead
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      @levar = obj
      i += 1
    end
  end
end

obj = TheClass.new

run_benchmark(100) do
  obj.set_value_loop(obj)
end
