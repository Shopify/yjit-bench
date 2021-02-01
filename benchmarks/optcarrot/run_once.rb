require_relative "lib/optcarrot"

puts('*** RUNNING BENCHMARK ***')

rom_path = File.join(__dir__, "examples/Lan_Master.nes")
argv = ["--headless", "--frames", 200, "--no-print-video-checksum", rom_path]
nes = Optcarrot::NES.new(argv).run
