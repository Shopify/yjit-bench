require_relative 'test_helper'
require_relative '../lib/windows_pinning'
require 'rbconfig'

describe WindowsPinning do
  # Records the calls WindowsPinning makes into kernel32, which exists only on Windows.
  def with_kernel32(pin: 0b1111)
    calls = []
    pin_self = ->(cpu) { calls << [:pin, cpu]; pin }
    restore = ->(mask) { calls << [:restore, mask] }
    raise_priority = ->(pid) { calls << [:raise_priority, pid] }
    WindowsPinning.stub(:pin_self, pin_self) do
      WindowsPinning.stub(:restore_affinity_mask, restore) do
        WindowsPinning.stub(:raise_priority, raise_priority) do
          yield calls
        end
      end
    end
  end

  it 'spawns the child while the runner is pinned, then raises the priority of the child' do
    with_kernel32 do |calls|
      real_spawn = Process.method(:spawn)
      spawned = ->(*args, **opts) { calls << :spawn; real_spawn.call(*args, **opts) }
      pid = Process.stub(:spawn, spawned) do
        WindowsPinning.spawn(3, {}, RbConfig.ruby, '-e', 'exit 0')
      end
      Process.wait(pid)
      assert_equal [[:pin, 3], :spawn, [:restore, 0b1111], [:raise_priority, pid]], calls
    end
  end

  it 'returns what Kernel#system would' do
    with_kernel32 do
      assert_equal true, WindowsPinning.system(0, {}, RbConfig.ruby, '-e', 'exit 0')
      assert_equal false, WindowsPinning.system(0, {}, RbConfig.ruby, '-e', 'exit 3')
      assert_equal 3, $?.exitstatus
      assert_nil WindowsPinning.system(0, {}, 'ruby-bench-no-such-command')
      assert_equal 127, $?.exitstatus
    end
  end

  it 'passes the environment and options to the child' do
    with_kernel32 do
      r, w = IO.pipe
      WindowsPinning.system(0, { 'PIN_TEST' => 'yes' }, RbConfig.ruby, '-e', 'print ENV["PIN_TEST"]', out: w)
      w.close
      assert_equal 'yes', r.read
    ensure
      r&.close
    end
  end

  it 'runs the child unpinned if the runner could not pin itself' do
    with_kernel32(pin: nil) do |calls|
      assert_equal true, WindowsPinning.system(0, {}, RbConfig.ruby, '-e', 'exit 0')
      assert_equal [[:pin, 0]], calls
    end
  end
end
