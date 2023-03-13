require 'harness'

def foo
  throw 'error'
end

def foo1
  foo
end

def foo2
  foo1
end

def foo3
  begin
    foo2
  rescue => err
    err
  end
end

run_benchmark(50) do
  i = 0
  while i < 10_000
    # Call 10 times to reduce loop overhead
    foo3
    foo3
    foo3
    foo3
    foo3
    foo3
    foo3
    foo3
    foo3
    foo3
    i += 1
  end
end
