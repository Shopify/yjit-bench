# frozen_string_literal: true

# Windows has no taskset, so the runner pins a benchmark from outside the benchmark process, as
# taskset does on Linux. A child process inherits the affinity mask of its parent when it is
# created, so the runner narrows its own mask for the duration of the spawn. The priority class
# is not inherited, so it and the power throttling opt-out are set on the child by its PID.
module WindowsPinning
  HIGH_PRIORITY_CLASS = 0x80
  PROCESS_SET_INFORMATION = 0x0200
  PROCESS_POWER_THROTTLING = 4 # PROCESS_INFORMATION_CLASS::ProcessPowerThrottling
  # PROCESS_POWER_THROTTLING_STATE that turns off the EXECUTION_SPEED throttling Windows 11 may
  # apply to a windowless process: Version, ControlMask and StateMask.
  NO_EXECUTION_SPEED_THROTTLING = [1, 1, 0].pack('L3').freeze

  class << self
    # Like Kernel#system, but the command runs pinned to the given CPU. If pinning fails, the
    # command runs unpinned with a warning.
    def system(cpu, env, *command, **options)
      pid = spawn(cpu, env, *command, **options)
    rescue SystemCallError
      # Let Kernel#system fail the same way, so the result and $? match an unpinned run.
      Kernel.system(env, *command, **options)
    else
      Process.wait(pid)
      $?.success?
    end

    def spawn(cpu, env, *command, **options)
      previous_mask = pin_self(cpu)
      begin
        pid = Process.spawn(env, *command, **options)
      ensure
        restore_affinity_mask(previous_mask) if previous_mask
      end
      raise_priority(pid) if previous_mask
      pid
    end

    private

    # Narrows the affinity of this process to the CPU, and returns its previous mask.
    def pin_self(cpu)
      load_fiddle
      # Etc.nprocessors counts the CPUs of every processor group, but the mask holds those of one group only.
      if cpu >= Fiddle::SIZEOF_VOIDP * 8
        warn "Not pinning to CPU #{cpu}, which is out of the affinity mask"
        return nil
      end
      previous_mask = affinity_mask
      set_affinity_mask(1 << cpu)
      previous_mask
    rescue LoadError, StandardError => e
      warn "Failed to pin the benchmark: #{e.message}"
      nil
    end

    # The child keeps the mask it inherited, so only the runner is affected if this fails.
    def restore_affinity_mask(mask)
      set_affinity_mask(mask)
    rescue StandardError => e
      warn "Failed to restore the affinity of the runner: #{e.message}"
    end

    def raise_priority(pid)
      process = function('OpenProcess', [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_VOIDP)
        .call(PROCESS_SET_INFORMATION, 0, pid)
      raise "OpenProcess failed" if process.null?
      begin
        set_priority_class = function('SetPriorityClass', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        raise "SetPriorityClass failed" if set_priority_class.call(process, HIGH_PRIORITY_CLASS).zero?

        set_information = function('SetProcessInformation', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        state = NO_EXECUTION_SPEED_THROTTLING.dup
        raise "SetProcessInformation failed" if set_information.call(process, PROCESS_POWER_THROTTLING, state, state.bytesize).zero?
      ensure
        function('CloseHandle', [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT).call(process)
      end
    rescue StandardError => e
      warn "Failed to raise the priority of the benchmark: #{e.message}"
    end

    def affinity_mask
      process_mask = [0].pack('J')
      system_mask = [0].pack('J')
      get_affinity = function('GetProcessAffinityMask', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
      raise "GetProcessAffinityMask failed" if get_affinity.call(current_process, process_mask, system_mask).zero?
      process_mask.unpack1('J')
    end

    def set_affinity_mask(mask)
      set_affinity = function('SetProcessAffinityMask', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_UINTPTR_T], Fiddle::TYPE_INT)
      raise "SetProcessAffinityMask failed" if set_affinity.call(current_process, mask).zero?
    end

    def current_process
      function('GetCurrentProcess', [], Fiddle::TYPE_VOIDP).call
    end

    def function(name, args, ret)
      @kernel32 ||= Fiddle.dlopen("kernel32")
      Fiddle::Function.new(@kernel32[name], args, ret)
    end

    def load_fiddle
      require 'fiddle'
    rescue LoadError
      # fiddle is a bundled gem since Ruby 3.5, which Bundler hides unless the Gemfile lists it.
      raise unless defined?(Bundler) && defined?(Gem::BUNDLED_GEMS.force_activate)
      Gem::BUNDLED_GEMS.force_activate("fiddle")
      require 'fiddle'
    end
  end
end
