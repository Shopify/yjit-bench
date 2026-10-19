# Every worker builds a deep, production-like machine stack by bouncing
# Ruby -> C -> Ruby -> C through a C extension whose frames hold many stack
# slots: live VALUEs, interior pointers, C pointers and scalars. At the bottom
# of the stack it allocates garbage and runs a minor GC, so every collection
# scans the whole stack conservatively (gc_mark_maybe). Objects referenced
# only from C stack slots are checked when each frame returns; a missed
# conservative root raises RactorStackScan::CorruptionError.
#
# Each worker does the same work at every Ractor count.

Warning[:experimental] = false

require_relative "../../lib/harness/loader"
require "digest"
require "fileutils"
require "shellwords"

def env_int(name, default, range = 0..)
  value = Integer(ENV.fetch(name, default))
  raise ArgumentError, "#{name} must be in #{range}" unless range.cover?(value)
  value
end

DEPTH = env_int("RACTOR_CONSERVATIVE_STACK_DEPTH", 48)
FRAME_SLOTS = env_int("RACTOR_CONSERVATIVE_STACK_FRAME_SLOTS", 256, 1..)
FRAME_SCALARS = env_int("RACTOR_CONSERVATIVE_STACK_FRAME_SCALARS", 256)
DESCENTS = env_int("RACTOR_CONSERVATIVE_STACK_DESCENTS", 40, 1..)
LEAF_ALLOCS = env_int("RACTOR_CONSERVATIVE_STACK_LEAF_ALLOCS", 100_000)
POOL_SIZE = env_int("RACTOR_CONSERVATIVE_STACK_POOL_SIZE", 20_000, 1..)

def build_extension
  ext_dir = File.join(__dir__, "ext")
  sources = %w[ractor_stack_scan.c extconf.rb].map { |f| File.read(File.join(ext_dir, f)) }
  flags = RbConfig::CONFIG.values_at("CC", "CFLAGS", "optflags", "debugflags", "configure_args")
  key = Digest::SHA256.hexdigest([*sources, RUBY_PLATFORM, RUBY_REVISION, RbConfig.ruby, *flags].join("\0"))[0, 16]
  build_dir = File.join(__dir__, "build", key)
  lib = File.join(build_dir, "ractor_stack_scan.#{RbConfig::CONFIG["DLEXT"]}")

  FileUtils.mkdir_p(build_dir)
  File.open(File.join(build_dir, ".lock"), File::RDWR | File::CREAT, 0o644) do |lock|
    lock.flock(File::LOCK_EX)
    Dir.chdir(build_dir) do
      setup_cmds([[RbConfig.ruby, File.join(ext_dir, "extconf.rb")].shelljoin]) unless File.exist?("Makefile")
      setup_cmds([ENV.fetch("MAKE", "make")])
    end
  end
  lib
end

require build_extension

max_slots = RactorStackScan::MAX_FRAME_SLOTS
slot_kinds = RactorStackScan::SLOT_KINDS
if FRAME_SLOTS > max_slots || FRAME_SLOTS % slot_kinds != 0
  raise ArgumentError, "RACTOR_CONSERVATIVE_STACK_FRAME_SLOTS must be a multiple of #{slot_kinds} up to #{max_slots}"
end
if FRAME_SCALARS > max_slots
  raise ArgumentError, "RACTOR_CONSERVATIVE_STACK_FRAME_SCALARS must be <= #{max_slots}"
end
if DEPTH > RactorStackScan::MAX_DEPTH
  raise ArgumentError, "RACTOR_CONSERVATIVE_STACK_DEPTH must be <= #{RactorStackScan::MAX_DEPTH}"
end

# A native stack overflow in a worker Ractor crashes the process instead of
# raising SystemStackError. Each level also needs about 3 KiB for the VM frames
# of the Ruby -> C round trip, measured on arm64 macOS.
word = RactorStackScan::WORD_SIZE
frame_bytes = (FRAME_SLOTS + FRAME_SCALARS + 1) * word + RactorStackScan::MAX_OWNED_STRING_LEN
vm_bytes_per_level = 3 * 1024
estimated_stack = (DEPTH + 1) * (frame_bytes + vm_bytes_per_level)
thread_stack = [ENV["RUBY_THREAD_MACHINE_STACK_SIZE"]&.to_i || 128 * 1024 * word, 16 * 1024 * word].max
if estimated_stack > thread_stack * 9 / 10
  raise ArgumentError, "estimated machine stack #{estimated_stack / 1024} KiB exceeds 90% of the " \
                       "Ractor thread stack (#{thread_stack / 1024} KiB); lower the depth or frame size, " \
                       "or raise RUBY_THREAD_MACHINE_STACK_SIZE"
end

GC_START_KWARGS = { full_mark: false, immediate_sweep: true }
GC_START_KWARGS[:global] = false if GC.method(:start).parameters.include?([:key, :global])
Ractor.make_shareable(GC_START_KWARGS)

class StackWalker
  def initialize
    @pool = Array.new(POOL_SIZE) do |i|
      case i % 6
      when 0 then "pooled string #{i}"
      when 1 then "long pooled string #{i} " * 32
      when 2 then [i, i.to_s, :pooled]
      when 3 then { key: i, value: i.to_s }
      when 4 then Object.new
      else (2**70) + i
      end
    end
    @retained = Array.new([POOL_SIZE / 4, 1].max)
    @retain_cursor = 0
  end

  def run
    DESCENTS.times { descend(DEPTH) }
  end

  private

  def descend(depth)
    return leaf if depth.negative?

    RactorStackScan.native_frame(self, depth, @pool, FRAME_SLOTS, FRAME_SCALARS) { |next_depth| descend(next_depth) }
  end

  def leaf
    i = 0
    rounds = LEAF_ALLOCS / 4
    while i < rounds
      str = "churn #{i}"
      hash = { [str, i] => str }
      if i % 16 == 0
        @retained[@retain_cursor] = hash
        @retain_cursor = (@retain_cursor + 1) % @retained.size
      end
      i += 1
    end
    GC.start(**GC_START_KWARGS)
  end
end

run_benchmark(5) do |_num_ractors = 0|
  StackWalker.new.run
end
