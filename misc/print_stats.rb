#!/usr/bin/env ruby

def print_stats(stats)

  print_counters(stats, prefix: 'send_', prompt: 'method call exit reasons: ')
  print_counters(stats, prefix: 'invokesuper_', prompt: 'invokesuper exit reasons: ')
  print_counters(stats, prefix: 'leave_', prompt: 'leave exit reasons: ')
  print_counters(stats, prefix: 'gbpp_', prompt: 'getblockparamproxy exit reasons: ')
  print_counters(stats, prefix: 'getivar_', prompt: 'getinstancevariable exit reasons:')
  print_counters(stats, prefix: 'setivar_', prompt: 'setinstancevariable exit reasons:')
  print_counters(stats, prefix: 'oaref_', prompt: 'opt_aref exit reasons: ')
  print_counters(stats, prefix: 'expandarray_', prompt: 'expandarray exit reasons: ')
  print_counters(stats, prefix: 'opt_getinlinecache_', prompt: 'opt_getinlinecache exit reasons: ')
  print_counters(stats, prefix: 'invalidate_', prompt: 'invalidation reasons: ')

  total_exits = total_exit_count(stats)

  # Number of instructions that finish executing in YJIT
  retired_in_yjit = stats[:exec_instruction] - total_exits

  # Average length of instruction sequences executed by YJIT
  avg_len_in_yjit = retired_in_yjit.to_f / total_exits

  # Proportion of instructions that retire in YJIT
  total_insns_count = retired_in_yjit + stats[:vm_insns_count]
  yjit_ratio_pct = 100.0 * retired_in_yjit.to_f / total_insns_count

  $stderr.puts "bindings_allocations:  " + ("%10d" % stats[:binding_allocations])
  $stderr.puts "bindings_set:          " + ("%10d" % stats[:binding_set])
  $stderr.puts "compiled_iseq_count:   " + ("%10d" % stats[:compiled_iseq_count])
  $stderr.puts "compiled_block_count:  " + ("%10d" % stats[:compiled_block_count])
  $stderr.puts "invalidation_count:    " + ("%10d" % stats[:invalidation_count])
  $stderr.puts "constant_state_bumps:  " + ("%10d" % stats[:constant_state_bumps])
  $stderr.puts "inline_code_size:      " + ("%10d" % stats[:inline_code_size])
  $stderr.puts "outlined_code_size:    " + ("%10d" % stats[:outlined_code_size])
  $stderr.puts "total_exit_count:      " + ("%10d" % total_exits)
  $stderr.puts "total_insns_count:     " + ("%10d" % total_insns_count)
  $stderr.puts "vm_insns_count:        " + ("%10d" % stats[:vm_insns_count])
  $stderr.puts "yjit_insns_count:      " + ("%10d" % stats[:exec_instruction])
  $stderr.puts "ratio_in_yjit:         " + ("%9.1f" % yjit_ratio_pct) + "%"
  $stderr.puts "avg_len_in_yjit:       " + ("%10.1f" % avg_len_in_yjit)

  print_sorted_exit_counts(stats, prefix: "exit_")
end

def print_sorted_exit_counts(stats, prefix:, how_many: 20, left_pad: 4)
  exits = []
  stats.each do |k, v|
    if k.start_with?(prefix)
      exits.push [k.to_s.delete_prefix(prefix), v]
    end
  end

  exits = exits.sort_by { |name, count| -count }[0...how_many]
  total_exits = total_exit_count(stats)

  top_n_total = exits.map { |name, count| count }.sum
  top_n_exit_pct = 100.0 * top_n_total / total_exits

  $stderr.puts "Top-#{how_many} most frequent exit ops (#{"%.1f" % top_n_exit_pct}% of exits):"

  longest_insn_name_len = exits.map { |name, count| name.length }.max
  exits.each do |name, count|
    padding = longest_insn_name_len + left_pad
    padded_name = "%#{padding}s" % name
    padded_count = "%10d" % count
    percent = 100.0 * count / total_exits
    formatted_percent = "%.1f" % percent
    $stderr.puts("#{padded_name}: #{padded_count} (#{formatted_percent}%)" )
  end
end

def total_exit_count(stats, prefix: "exit_")
  total = 0
  stats.each do |k,v|
    total += v if k.start_with?(prefix)
  end
  total
end

def print_counters(counters, prefix:, prompt:)
  $stderr.puts(prompt)
  counters = counters.filter { |key, _| key.start_with?(prefix) }
  counters.filter! { |_, value| value != 0 }
  counters.transform_keys! { |key| key.to_s.delete_prefix(prefix) }

  if counters.empty?
    $stderr.puts("    (all relevant counters are zero)")
    return
  end

  counters = counters.to_a
  counters.sort_by! { |(_, counter_value)| counter_value }
  longest_name_length = counters.max_by { |(name, _)| name.length }.first.length
  total = counters.sum { |(_, counter_value)| counter_value }

  counters.reverse_each do |(name, value)|
    percentage = value.fdiv(total) * 100
    $stderr.printf("    %*s %10d (%4.1f%%)\n", longest_name_length, name, value, percentage);
  end
end

require 'json'
File.readlines(ARGV.first).each do |json|
  request = JSON.parse(json, symbolize_names: true)
  stats = JSON.parse(request[:result][:_raw], symbolize_names: true)
  print_stats(stats[:yjit])

  puts "\n" * 3
  puts "=" * 40
  puts "\n" * 3
end