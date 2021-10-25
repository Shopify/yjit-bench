# frozen_string_literal: true

require 'csv'

def rewrite_samples(path)
  csv = CSV.read(path, headers: true)
  data = build_structure(csv)
  write_new_file(data)
end

def build_structure(csv)
  csv.map do |row|
    name = row["Ruby"]
    name += " #{row["VM"]}" if row["VM"] && row["VM"] != "-"
    # don't do this at home kids (or with unknown input)
    times = eval row["warmup times"]
    times += eval row["run times"]
    [name, times]
  end
end

def write_new_file(data)
  CSV.open("samples.csv", "w") do |csv|
    names = data.map { |name, _| name}
    csv << names
    times = data.map { |_, times| times }
    max_times = times.map(&:size).max
    max_times.times do |i|
      row_times = times.map {|all_times| all_times[i]}
      csv << row_times
    end
  end
end


rewrite_samples "Rubykon Benchmarks 2020-08.csv"
