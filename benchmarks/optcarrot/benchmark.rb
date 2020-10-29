require 'harness'

# I'm too lazy to type `-Ilib` every time...
require_relative "lib/optcarrot"

run_benchmark do
    rom_path = File.join(__dir__, "examples/Lan_Master.nes")
    argv = ["--headless", "--frames", 200, "--no-print-video-checksum", rom_path]
    nes = Optcarrot::NES.new(argv).run
end
