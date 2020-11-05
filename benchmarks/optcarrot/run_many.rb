require_relative "lib/optcarrot"

puts('*** RUNNING BENCHMARK ***')

30.times do |i|
    puts("iteration #{i+1}")

    rom_path = File.join(__dir__, "examples/Lan_Master.nes")
    argv = ["--headless", "--frames", 100, "--no-print-video-checksum", rom_path]
    nes = Optcarrot::NES.new(argv).run
end
