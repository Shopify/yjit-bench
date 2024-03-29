require_relative '../../harness/loader'
require_relative "lib/optcarrot"

rom_path = File.join(__dir__, "examples/Lan_Master.nes")
nes = Optcarrot::NES.new(["--headless", rom_path])
nes.reset

run_benchmark(10) do
  200.times { nes.step }
end
