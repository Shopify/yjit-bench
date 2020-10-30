require 'harness'

run_benchmark(50) do
    # 5M calls
    5000000.times do |i|
        itself
    end
end
