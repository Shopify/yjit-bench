require_relative '../../harness/loader'

# Protoboeuf decoder
require_relative 'benchmark_pb'

Dir.chdir __dir__
fake_msg_bins = Marshal.load(File.binread('encoded_msgs.bin'))

run_benchmark(20) do
  fake_msg_bins.each { |bin| ProtoBoeuf::ParkingLot.decode bin }
end
