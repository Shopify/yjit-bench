require 'harness'

run_benchmark do
    # 10M calls
    10000000.times do |i|
        itself
    end
end
