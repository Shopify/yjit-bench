require_relative '../harness/loader'

run_benchmark(50) do
  # 500K calls
  500000.times do |i|
    # Call 10 times to reduce loop overhead, emphasize call performance
    itself
    itself
    itself
    itself
    itself
    itself
    itself
    itself
    itself
    itself
  end
end
