require 'harness'

class TheClass
    def initialize
        @levar = 1
    end

    def get_value_loop
        sum = 0

        i = 0
        while i < 5000000
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
