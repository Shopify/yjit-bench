require "benchmark/ips"

def foo_pos(a, b)
  a + b
end

def foo_kw(a:, b:)
  a + b
end

Benchmark.ips do |x|
  x.report("call-pos") { foo_pos(1, 2) }
  x.report("call-kw") { foo_kw(a: 1, b: 2) }
end
