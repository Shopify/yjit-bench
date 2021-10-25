require_relative '../spec_helper'

module Benchmark::Avg
  RSpec.describe Job do
    let(:block) { proc {sleep 0.01}}
    let(:label) {'some label'}
    subject(:job) {described_class.new label, block}

    it { is_expected.not_to be_nil}

    describe 'reports' do
      let(:fake_io) {FakeIO.new}
      before :each do
        $stdout = fake_io
        job.run 0.02, 0.03
        $stdout = STDOUT
      end

      it "prints a note about the warm up phase being over" do
        expect(fake_io.output).to match /finish.+warm up.*#{label}/i
      end

      it "prints a note about the runtime phase being over" do
        expect(fake_io.output).to match /finish.+measur.+run.*#{label}/i
      end
      
      shared_examples_for 'static run time report' do
        it "gets the reportright" do
          expect(subject).to include label
          expect(subject).to match /(6[012345]\d\d|5[456789]\d\d)\.\d* i\/min/
          expect(subject).to match /0\.01\d* s/
          expect(subject).to match /([012345678]\.\d*|0)%/
        end
      end

      describe '#warmup_report' do
        subject(:warmup_report) { job.warmup_report}

        it_behaves_like "static run time report"
      end

      describe '#runtime_report' do
        subject(:runtime_report) { job.runtime_report}

        it_behaves_like "static run time report"
      end

    end
  end
end
