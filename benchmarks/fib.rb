require 'harness'

def fib(n)
    if n < 2
        return n
    end

    return fib(n-1) + fib(n-2)
end

run_benchmark do
    fib(32)
end
