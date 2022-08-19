require 'harness'

class TheClass
  def initialize
    @v0 = 1
    @v1 = 2
    @v3 = 3
    @levar = 1
  end

  def get_value_loop
    sum = 0

    # 1M
    i = 0
    while i < 1000000
      # 10 times to de-emphasize loop overhead
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      sum += @levar
      i += 1
    end

    return sum
  end
end

obj = TheClass.new

run_benchmark(100) do
  obj.get_value_loop
end
