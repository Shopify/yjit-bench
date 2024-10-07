#!/usr/bin/env ruby

require_relative 'stats'
require 'json'
begin
  require 'gruff'
rescue LoadError
  Gem.install('gruff')
  gem 'gruff'
  require 'gruff'
end

def render_graph(json_path, png_path, title_font_size: 16.0, legend_font_size: 12.0, marker_font_size: 10.0)
  json = JSON.load_file(json_path)
  ruby_descriptions = json.fetch("metadata")
  data = json.fetch("raw_data")
  baseline = ruby_descriptions.first.first
  bench_names = data.first.last.keys

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

  ruby_descriptions.each do |ruby, description|
    speedups = bench_names.map { |bench|
      baseline_times = data.fetch(baseline).fetch(bench).fetch("bench")
      times = data.fetch(ruby).fetch(bench).fetch("bench")
      Stats.new(baseline_times).mean / Stats.new(times).mean
    }
    g.data "#{ruby}: #{description}", speedups
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

  json_path = ARGV.first
  abort parser.help if json_path.nil?

  png_path = json_path.sub(/\.json\z/, '.png')
  render_graph(json_path, png_path, **args)

  open = %w[open xdg-open].find { |open| system("which #{open} >/dev/null 2>/dev/null") }
  system(open, png_path) if open
end
