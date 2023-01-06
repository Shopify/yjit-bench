require_relative '../harness/harness'

# Using Module#prepend to enable TracePoint right before #run_benchmark
# while also reusing the original implementation.
self.singleton_class.prepend Module.new {
  def run_benchmark(*)
    frames = []
    c_calls = Hash.new { 0 }
    c_loops = Hash.new { 0 }
    rb_calls = Hash.new { 0 }

    method_trace = TracePoint.new(:call, :c_call, :return, :c_return) do |tp|
      # Keep track of call frames to get the caller of :b_call
      case tp.event
      when :call, :c_call
        method_name = "#{tp.defined_class}##{tp.method_id}"
        frames.push([tp.event, method_name])
      when :return, :c_return
        frames.pop
      end

      # Count method calls
      case tp.event
      when :c_call
        c_calls[method_name] += 1
      when :call
        rb_calls[method_name] += 1
      end
    end

    block_trace = TracePoint.new(:b_call) do |tp|
      caller_event, caller_method = frames.last

      # Count block calls only when the caller is a C method
      if caller_event == :c_call
        c_loops[caller_method] += 1
      end
    end

    method_trace.enable
    block_trace.enable
    super
  ensure
    block_trace.disable
    method_trace.disable

    c_loops_total = c_loops.sum(&:last)
    c_loops = c_loops.sort_by { |_method, count| -count }.first(100)
    c_loops_ratio = 100.0 * c_loops.sum(&:last) / c_loops_total
    puts "Top #{c_loops.size} block calls by C methods (#{'%.1f' % c_loops_ratio}% of all #{c_loops_total} calls):"
    c_loops.each do |method, count|
      puts '%8d (%4.1f%%) %s' % [count, 100.0 * count / c_loops_total, method]
    end
    puts

    c_calls_total = c_calls.sum(&:last)
    c_calls = c_calls.sort_by { |_method, count| -count }.first(100)
    c_calls_ratio = 100.0 * c_calls.sum(&:last) / c_calls_total
    puts "Top #{c_calls.size} C method calls (#{'%.1f' % c_calls_ratio}% of all #{c_calls_total} calls):"
    c_calls.sort_by(&:last).reverse.first(100).each do |method, count|
      puts '%8d (%4.1f%%) %s' % [count, 100.0 * count / c_calls_total, method]
    end
    puts

    rb_calls_total = rb_calls.sum(&:last)
    rb_calls = rb_calls.sort_by { |_method, count| -count }.first(100)
    rb_calls_ratio = 100.0 * rb_calls.sum(&:last) / rb_calls_total
    puts "Top #{rb_calls.size} Ruby method calls (#{'%.1f' % rb_calls_ratio}% of all #{rb_calls_total} calls):"
    rb_calls.sort_by(&:last).reverse.first(100).each do |method, count|
      puts '%8d (%4.1f%%) %s' % [count, 100.0 * count / rb_calls_total, method]
    end
  end
}
