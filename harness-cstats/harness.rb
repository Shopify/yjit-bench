require_relative '../harness/harness'

# Using Module#prepend to enable TracePoint right before #run_benchmark
# while also reusing the original implementation.
self.singleton_class.prepend Module.new {
  def run_benchmark(*)
    c_calls = Hash.new { 0 }
    c_loops = Hash.new { 0 }

    trace_point = TracePoint.new(:c_call) do |tp|
      method_name = "#{tp.defined_class}##{tp.method_id}"
      c_calls[method_name] += 1

      case tp.method_id
      when /(\A|_)each(_|\z)/, /(\A|_)map\!?\z/
        c_loops[method_name] += tp.self.size if tp.self.respond_to?(:size)
      when :times
        c_loops[method_name] += Integer(tp.self)
      when :loop
        c_loops[method_name] += 1 # can't predict it properly
      end
    end

    trace_point.enable
    super
  ensure
    trace_point.disable

    puts "Top C loop method iterations:"
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
