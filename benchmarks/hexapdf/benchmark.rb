require_relative '../../harness/setup'
Dir.chdir __dir__
use_gemfile

# Based on https://github.com/gettalong/hexapdf/blob/master/benchmark/line_wrapping/hexapdf_composer.rb
# Take a copy of The Odyssey (trans: Samuel Butler) and paginate it to a given line width, in this case 50.
# The original timed several variations (low-level vs Composer interface; TTF vs non-TTF). We don't collect
# a lot of individual variant data.

require "hexapdf"
require "fileutils"

IN_FILENAME = "odyssey.txt"
WIDTH = 50
HEIGHT = 1000

EXPECTED_SIZE = 569797

Dir["/tmp/hexapdf-result*.pdf"].each { |file| FileUtils.rm file }

index = 0
run_benchmark(10) do
  ## TTF benchmark (v. slow)
  #HexaPDF::Composer.create(OUT_FILENAME, page_size: [0, 0, WIDTH, HEIGHT], margin: 0) do |pdf|
  #  pdf.text(File.read(IN_FILENAME), font_features: {kern: false},
  #           font: "./DejaVuSans.ttf", font_size: 10, last_line_gap: true,
  #           line_spacing: {type: :fixed, value: 11.16})
  #end

  # Non-TTF benchmark
  index += 1
  out_filename = "/tmp/hexapdf-result-#{ "%03d" % index }.pdf"


  composer = HexaPDF::Composer.new(page_size: [0, 0, WIDTH, HEIGHT], margin: 0)
  composer.text(File.read(IN_FILENAME), font_features: {kern: false},
                font: "Times", font_size: 10, last_line_gap: true,
                line_spacing: {type: :fixed, value: 11.16})
  composer.document.trailer[:ID] = ['benchmark', 'benchmark']
  composer.write(out_filename, update_fields: false)
end

Dir["/tmp/hexapdf-result*.pdf"].each do |file|
  sz = File.stat(file).size
  raise "Incorrect size #{sz} for file #{file} (expected #{EXPECTED_SIZE})!" unless sz == EXPECTED_SIZE
  FileUtils.rm file
end
