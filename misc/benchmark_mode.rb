# frozen_string_literal: true

require "etc"
require "open3"

module BenchmarkMode
  BENCH_SET = "bench"
  OTHER_SET = "other"

  module Helpers
    extend self

    def list_to_ints(list)
      list
        &.split(',')
        &.flat_map { |s| a, b = s.split('-').map(&:to_i); b ? a.upto(b).to_a : [a] }
    end
  end

  class << self
    def engage!(nice: nil)
      Nice.renice!(nice || -15)

      return unless bench_cpus = find_bench_cpus

      # Create "bench" cpuset for our task (and forks).
      bench_tasks = [$$]
      CpuSet.new(BENCH_SET, cpus: bench_cpus, tasks: bench_tasks, sched_load_balance: '0').create

      # Put all other tasks in "other" cpuset.
      other_tasks = all_tasks - bench_tasks
      other_cpus = all_cpus - bench_cpus
      CpuSet.new(OTHER_SET, cpus: other_cpus, tasks: other_tasks).create

      # Disable the hyper thread siblings of our CPUs
      # so that nothing gets put on the physical core we are using.
      @hyper_thread_siblings = []
      bench_cpus.each do |cpu|
        @hyper_thread_siblings.concat(HyperThreading.new(cpu:).disable)
      end

      # Pin current task (coordinator) to first CPU
      # so the benchmarks can run alone on the second.
      CpuAffinity.pin!(bench_cpus.first, $$)

      bench_cpus.last
    end
    alias enable! engage!

    def disengage!
      [OTHER_SET, BENCH_SET].each do |set|
        CpuSet.new(set).destroy
      end

      # If we know which ones we took offline, restore those.
      if @hyper_thread_siblings&.any?
        @hyper_thread_siblings.each do |sib|
          CPU.enable(sib)
        end
      else
        # Otherwise just re-enable all CPUs.
        Sudo.write(Dir.glob("#{CPU::ROOT}/cpu*/online"), "1")
      end

      # Don't return the above value.
      nil
    end
    alias disable! disengage!

    # Get thread id's of all running processes.
    def all_tasks
      (CpuSet.read(:tasks) || `ps -eo tid=`).lines.map(&:strip).map(&:to_i)
    end

    def all_cpus
      return @all_cpus if defined?(@all_cpus)

      # Read from root cpuset so our view is not limited by any current cpuset.
      # Transform a list like "0,2-4,7" into an array of integers.
      @all_cpus = Helpers.list_to_ints(CpuSet.read(:cpus))

      # If that didn't work just guess at it.
      @all_cpus ||= (0 ... Etc.nprocessors).to_a
    end

    # TODO: look at cpus in use, grab the ones with the least amount of (kernel) tasks?
    def find_bench_cpus
      # If we have enough CPUs, just pick some:
      # one for the coordinator
      # one for the actual benchmarks
      [1, 2] if all_cpus.size > 4
    end
  end

  attr_reader :name, :path

  module Sudo
    extend self

    def log(msg)
      STDERR.puts msg
    end

    def sudo(*command, **kwargs)
      log "$ sudo #{command.join(" ")}"
      system("sudo", *command, **kwargs)
    end

    def write(path, content, verbose: true)
      paths = Array(path)
      return unless paths.all? { |p| File.exist?(p) }

      # Limit to X items at a time to avoid command line argument limits.
      paths.each_slice(50) do |paths|
        cmd = ["sudo", "tee", *paths]
        if verbose
          log "$ echo #{content} | sudo #{cmd.join(" ")}"
        end

        Open3.popen3(*cmd) do |stdin, stdout, stderr, thread|
          stdin.write(content)
          stdin.close
          # No such process
          # Invalid argument
          err = stderr.read.strip
          if !err.empty? && err !~ /No such process|Invalid argument/
            if !verbose
              log "$ echo #{content} | sudo #{cmd.join(" ")}"
            end
            puts err
          end
        end
      end
    end
  end

  class CPU
    ROOT = "/sys/devices/system/cpu"

    class << self
      include Sudo

      def enable(n)
        set(n, "online", "1")
      end

      def disable(n)
        set(n, "online", "0")
      end

      def set(n, key, val)
        write("#{ROOT}/cpu#{n}/#{key}", val.to_s)
      end
    end
  end

  class HyperThreading
    attr_reader :cpu

    def initialize(cpu:)
      @cpu = cpu
    end

    def list_path
      "#{CPU::ROOT}/cpu#{cpu}/topology/thread_siblings_list"
    end

    def enable
      set("1")
    end

    def disable
      set("0")
    end

    def set(val)
      disabled = []

      if File.exist?(list_path)
        siblings = Helpers.list_to_ints(File.read(list_path))
        siblings.each do |sib|
          next if sib == cpu

          disabled << sib
          CPU.set(sib, "online", val)
        end
      end

      disabled
    end
  end

  class CpuSet
    include Sudo

    # Man cpuset(7) says "/dev/cpuset" but mounting there may fail when /dev is a devtmpfs.
    DEFAULT_ROOT = "/cpusets"

    def self.find_root
      return @root if defined?(@root)

      unless File.read("/proc/filesystems").lines.detect { |line| line =~ /^nodev\s+cpuset$/ }
        return @root = nil
      end

      # If it's already mounted use the current path.
      File.read("/proc/mounts").lines.each do |line|
        if %r{^\S+ (?<mountpoint>/\S+) cgroup (?:[^ ]*,)?cpuset[, ]} =~ line
          return @root = mountpoint
        end
      end

      @root = DEFAULT_ROOT.then do |dir|
        Sudo.sudo("mkdir", "-p", dir) unless File.exist?(dir)

        Sudo.sudo("mount", "-t", "cpuset", "none", dir)

        # If the fs isn't mounted, return nil.
        dir if File.exist?("#{dir}/tasks")
      end
    end

    def self.read(key)
      path = "#{find_root}/#{key}"

      return unless File.exist?(path)

      File.read(path)
    end

    def initialize(name, cpus: nil, tasks: [], **kwargs)
      @name = name
      @cpus = cpus
      @tasks = tasks
      @settings = {cpu_exclusive: 1, cpus: Array(cpus).join(",")}.merge(kwargs)
    end

    def path
      root = self.class.find_root
      return unless root

      @path ||= File.join(root, @name)
    end

    def create
      return unless path

      unless File.directory?(path)
        sudo("mkdir", path)
      end

      # Both cpus and mems must be set in order to add tasks.
      # Default mems to the root value.
      @settings[:mems] ||= File.read("#{self.class.find_root}/mems").strip

      # Settings must be written before tasks can be added.
      @settings.each_pair do |key, value|
        write_setting(key, value)
      end

      # Now we can write the tasks.
      write_setting(:tasks, @tasks, verbose: false)
    end

    def write_setting(key, value, verbose: true)
      # If an array is provided (for "tasks") write each item individually.
      Array(value).each do |item|
        write("#{path}/#{key}", item, verbose:)
      end
    end

    def destroy
      return unless path && File.directory?(path)

      # Move tasks to parent cpuset as we cannot remove a set that still has tasks.
      root_tasks = "#{self.class.find_root}/tasks"
      File.read("#{path}/tasks").lines.each do |tid|
        write(root_tasks, tid, verbose: false)
      end

      sudo("rmdir", path)
    end
  end

  module Nice
    class << self
      include Sudo

      def renice!(priority)
        # Allow setting a negative priority without
        # needing this process (or any child) to be run as root.
        sudo("renice", priority.to_s, "-g", Process.getpgrp.to_s)
      end
    end
  end

  module CpuAffinity
    class << self
      include Sudo

      def pin!(cpu, pid)
        # The "p" and "c" options must be grouped together.
        sudo("taskset", "-pc", cpu.to_s, pid.to_s)
      end
    end
  end
end
