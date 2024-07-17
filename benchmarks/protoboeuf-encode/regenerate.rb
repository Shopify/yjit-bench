#!/usr/bin/env ruby

# frozen_string_literal: true

require "protoboeuf/codegen"
require "protoboeuf/parser"

proto_file = File.expand_path("benchmark.proto", __dir__)
out_file = File.expand_path("benchmark_pb.rb", __dir__)

unit = ProtoBoeuf.parse_file(proto_file)
unit.package = "proto_boeuf"
gen = ProtoBoeuf::CodeGen.new(unit, generate_types: false)
File.write(out_file, gen.to_ruby)
