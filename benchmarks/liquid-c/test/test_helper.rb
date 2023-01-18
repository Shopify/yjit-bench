# frozen_string_literal: true

require "minitest/autorun"
require "liquid/c"

if GC.respond_to?(:verify_compaction_references)
  # This method was added in Ruby 3.0.0. Calling it this way asks the GC to
  # move objects around, helping to find object movement bugs.
  begin
    GC.verify_compaction_references(double_heap: true, toward: :empty)
  rescue NotImplementedError
    puts "W: GC compaction not suppported by platform"
  end
end

# Enable auto-compaction in the GC if supported.
if GC.respond_to?(:auto_compact=)
  GC.auto_compact = true
end

GC.stress = true if ENV["GC_STRESS"]
