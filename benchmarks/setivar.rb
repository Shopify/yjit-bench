require 'harness'

class TheClass
    def initialize
        @levar = 1
    end

    def set_value_loop
        # 1M
        i = 0
        while i < 1000000
            # 10 times to de-emphasize loop overhead
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            @levar = i
            i += 1
        end
    end
end

obj = TheClass.new

run_benchmark(100) do
    obj.set_value_loop
end
