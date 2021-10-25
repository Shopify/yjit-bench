require_relative 'spec_helper'

module MCTS
  RSpec.describe Root do
    let(:game_state) {double 'game_state', dup: dupped,
                                           all_valid_moves: [move_1, move_2],
                                           finished?: false}
    let(:dupped) {double('dupped', dup: duppie).as_null_object}
    let(:duppie) {double('duppie',finished?: true, won?: true, dup: dupped2).as_null_object}
    let(:dupped2) {double("dupped2", dup: duppie2).as_null_object}
    let(:duppie2) {double('duppie2', finished?: true, won?: false).as_null_object}
    let(:move_1) {double 'move 1'}
    let(:move_2) {double 'move 2'}
    subject {Root.new game_state}

    it {is_expected.to be_root}

    describe '#explore_tree' do

      before :each do
        subject.explore_tree
      end

      it "creates a child" do
        expect(subject.children.size).to eq 1
      end

      it "the child has move 1 as a move" do
        expect(subject.children.first.move).to be move_2
      end

      it "gives the root a visit" do
        expect(subject.visits).to eq 1
        expect(subject.wins).to eq 1
      end

      it "selects it as the best node" do
        expect(subject.best_child).to eq subject.children.first
      end

      describe 'one more expand' do

        let(:game_state) do
          mine = double 'game_state', all_valid_moves: [move_1, move_2],
                                      finished?: false
          allow(mine).to receive(:dup).and_return(dupped, dupped2)
          mine
        end

        before :each do
          subject.explore_tree
        end

        it "creates a child" do
          expect(subject.children.size).to eq 2
        end

        it "the child has move 1 as a move" do
          expect(subject.children[1].move).to be move_1
        end

        it "gives the root a visit" do
          expect(subject.visits).to eq 2
          expect(subject.wins).to eq 1
        end

        it "selects the other still as the best node" do
          expect(subject.best_child).to eq subject.children.first
        end

      end
    end
  end
end
