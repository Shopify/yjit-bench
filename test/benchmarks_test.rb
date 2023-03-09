require_relative 'test_helper'
require 'yaml'

describe 'benchmarks.yml' do
  it 'has the same entries as /benchmarks' do
    yjit_bench = File.expand_path('..', __dir__)
    benchmarks_yml = YAML.load_file("#{yjit_bench}/benchmarks.yml")
    benchmarks_yml_files = benchmarks_yml.map { |name, meta| meta["file"] || name }
    benchmarks = Dir.glob("#{yjit_bench}/benchmarks/*").map do |entry|
      File.basename(entry).delete_suffix('.rb')
    end
    assert_equal benchmarks.sort, benchmarks_yml_files.uniq.sort
  end
end
