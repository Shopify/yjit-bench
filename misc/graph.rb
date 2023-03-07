#!/usr/bin/env ruby

require 'csv'
begin
  require 'gruff'
rescue LoadError
  Gem.install('gruff')
  gem 'gruff'
  require 'gruff'
end

def render_graph(csv_path, png_path, title_font_size: 16.0, legend_font_size: 12.0, marker_font_size: 10.0)
  ruby_descriptions_csv, table_csv = File.read(csv_path).split("\n\n", 2)
  ruby_descriptions = CSV.parse(ruby_descriptions_csv).to_h
  table = CSV.parse(table_csv)
  bench_names = table.drop(1).map(&:first)

  # ruby_descriptions, bench_names, table
  g = Gruff::Bar.new(1600)
  g.title = "Speedup ratio relative to #{ruby_descriptions.keys.first}"
  g.title_font_size = title_font_size
  g.theme = {
    colors: %w[#3285e1 #489d32 #e2c13e #8A6EAF #D1695E],
    marker_color: '#dddddd',
    font_color: 'black',
    background_colors: 'white'
  }
  g.labels = bench_names.map.with_index { |bench, index| [index, bench] }.to_h
  g.show_labels_for_bar_values = true
  g.bottom_margin = 30.0
  g.legend_margin = 4.0
  g.legend_font_size = legend_font_size
  g.marker_font_size = marker_font_size

  rubies = ruby_descriptions.map { |ruby, description| "#{ruby}: #{description}" }
  g.data rubies.first, [1.0] * bench_names.size
  rubies.drop(1).each_with_index do |ruby, index|
    speedup = table.drop(1).map do |row|
      num_rests = rubies.size - 1
      row.last(num_rests * 2).first(num_rests)[index]
    end
    g.data ruby, speedup.map(&:to_f)
  end
  g.write(png_path)
end

# This file may be used as a standalone command as well.
if $0 == __FILE__
  require 'optparse'

  args = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] CSV_PATH"
    opts.on('--title SIZE', 'title font size') do |v|
      args[:title_font_size] = v.to_f
    end
    opts.on('--legend SIZE', 'legend font size') do |v|
      args[:legend_font_size] = v.to_f
    end
    opts.on('--marker SIZE', 'marker font size') do |v|
      args[:marker_font_size] = v.to_f
    end
  end
  parser.parse!

  csv_path = ARGV.first
  abort parser.help if csv_path.nil?

  png_path = csv_path.sub(/\.csv\z/, '.png')
  render_graph(csv_path, png_path, **args)

  open = %w[open xdg-open].find { |open| system("which #{open} > /dev/null") }
  system(open, png_path) if open
end
