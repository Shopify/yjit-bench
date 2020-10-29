require 'harness'

class TheClass
    def initialize
        @levar = 1
    end

    def set_value_loop
        i = 0
        while i < 5000000
            @levar = i
            i += 1
        end
    end
end

obj = TheClass.new

run_benchmark do
    obj.set_value_loop
end
