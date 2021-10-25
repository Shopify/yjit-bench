require_relative 'spec_helper'

module Rubykon
  RSpec.describe GTPCoordinateConverter do

    subject {described_class.new(board)}
    let(:board) {Board.new size}

    shared_examples_for 'converting' do |gtp_string, index|
      describe '#from' do
        it "converts from #{gtp_string} to #{index}" do
          expect(subject.from(gtp_string)).to eq index
        end
      end

      describe '#to' do
        it "converts from #{index} to #{gtp_string}" do
          expect(subject.to(index)).to eq gtp_string
        end
      end
    end

    context '19x19' do
      let(:size) {19}

      it_behaves_like 'converting', 'A19', 0
      it_behaves_like 'converting', 'T1', 360
      it_behaves_like 'converting', 'D12', 136
    end

    context '9x9' do
      let(:size) {9}

      it_behaves_like 'converting', 'A9', 0
      it_behaves_like 'converting', 'J1', 80
      it_behaves_like 'converting', 'D7', 21
    end
  end
end
