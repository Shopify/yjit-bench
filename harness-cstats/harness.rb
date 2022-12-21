require_relative '../harness/harness'

# Using Module#prepend to enable TracePoint right before #run_benchmark
# while also reusing the original implementation.
self.singleton_class.prepend Module.new {
  def run_benchmark(*)
    frames = []
    c_calls = Hash.new { 0 }
    c_loops = Hash.new { 0 }

    method_trace = TracePoint.new(:call, :c_call, :return, :c_return) do |tp|
      # Keep track of call frames to get the caller of :b_call
      case tp.event
      when :call, :c_call
        method_name = "#{tp.defined_class}##{tp.method_id}"
        frames.push([tp.event, method_name])
      when :return, :c_return
        frames.pop
      end

      # Count C method calls
      if tp.event == :c_call
        c_calls[method_name] += 1
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

    puts "Top C method block iterations:"
    c_loops.sort_by(&:last).reverse_each do |method, count|
      puts '%8d %s' % [count, method]
    end
    puts

    puts "Top 100 C method calls:"
    c_calls.sort_by(&:last).reverse.first(100).each do |method, count|
      puts '%8d %s' % [count, method]
    end
  end
}
