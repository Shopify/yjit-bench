require 'harness'

run_benchmark do
    # 5M calls
    5000000.times do |i|
        itself
    end
end
