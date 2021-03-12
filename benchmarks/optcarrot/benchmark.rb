require 'harness'
require_relative "lib/optcarrot"

run_benchmark(5) do
    rom_path = File.join(__dir__, "examples/Lan_Master.nes")
    argv = ["--headless", "--frames", 200, "--no-print-video-checksum", rom_path]
    nes = Optcarrot::NES.new(argv).run
end
