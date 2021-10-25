require_relative 'spec_helper'

# also covers BenchmarkSuite
RSpec.describe Benchmark::Avg do
  let(:fake_io) {FakeIO.new}
  let(:fake_job) {create_fake_job}
  before :each do
    $stdout = fake_io
  end

  after :each do
    $stdout = STDOUT
  end

  describe 'A run with just one job' do
    before :each do
      allow(Benchmark::Avg::Job).to receive(:new).and_return fake_job
    end

    let!(:benchmark) do
      Benchmark.avg do |benchmark|
        benchmark.report 'Label' do
          # something
        end
      end
    end

    it "tries to create a job with the right label" do
      expect(Benchmark::Avg::Job).to have_received(:new).with('Label', anything)
    end

    it 'uses defaults for time' do
      expect(fake_job).to have_received(:run).with(30, 60)
    end

    it "prints the reports" do
      expect(fake_io).to match /warm up report 1/i
      expect(fake_io).to match /runtime report 1/i
    end

    it 'says that the reports are ready' do
      expect(fake_io).to match /reports/i
    end

    describe 'configuring via #config' do
      let!(:benchmark) do
        Benchmark.avg do |benchmark|
          benchmark.config warmup: 120, time: 150
          benchmark.report 'Label' do
            # something
          end
        end
      end

      it 'uses the configured times' do
        expect(fake_job).to have_received(:run).with(120, 150)
      end
    end
  end

  describe "Running multiple jobs" do

    let(:fake_job_2) {create_fake_job(2)}

    before :each do
      allow(Benchmark::Avg::Job).to receive(:new).and_return fake_job,
                                                             fake_job_2
    end

    let!(:benchmark) do
      Benchmark.avg do |benchmark|
        benchmark.config warmup: 34, time: 77
        benchmark.report 'Label' do
          # something
        end
        benchmark.report 'Label 2' do
          # someting 2
        end
      end
    end

    it "calls all the jobs with the appropriate times" do
      expect(fake_job).to have_received(:run).with 34, 77
      expect(fake_job_2).to have_received(:run).with 34, 77
    end

    it "prints the reports" do
      expect(fake_io).to match /warm up report 1/i
      expect(fake_io).to match /runtime report 1/i
      expect(fake_io).to match /warm up report 2/i
      expect(fake_io).to match /runtime report 2/i
    end

    it "created jobs with the right labels" do
      expect(Benchmark::Avg::Job).to have_received(:new).with("Label", anything)
      expect(Benchmark::Avg::Job).to have_received(:new).with("Label 2", anything)
    end
  end

  def create_fake_job(i = 1)
    double 'fake job', run: nil,
                       warmup_report:  "Warm up Report #{i}",
                       runtime_report:  "Runtime Report #{i}"
  end
end
