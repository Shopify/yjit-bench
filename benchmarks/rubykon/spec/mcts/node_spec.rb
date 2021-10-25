require_relative 'spec_helper'

module MCTS
  RSpec.describe Node do
    let(:game_state) {double 'game_state', all_valid_moves: [], finished?: false}
    let(:move) {double 'move'}
    let(:root) {Root.new game_state}
    subject {Node.new game_state, move, root}

    it {is_expected.not_to be_root}

    describe 'initialization' do
      it "has 0 visits" do
        expect(subject.visits).to eq 0
      end

      it "has 0 wins" do
        expect(subject.wins).to eq 0
      end

      it "has the right parent" do
        expect(subject.parent).to be root
      end

      it "has the right move" do
        expect(subject.move).to be move
      end
    end

    describe "#won" do
      it "increases the visit and wins count" do
        subject.won
        expect(subject.wins).to eq 1
        expect(subject.visits).to eq 1
      end
    end

    describe "#lost" do
      it "increases visits and does not increase wins" do
        subject.lost
        expect(subject.wins).to eq 0
        expect(subject.visits).to eq 1
      end
    end

    describe "#win_average" do
      it "is still 0 after losing" do
        subject.lost
        expect(subject.win_percentage).to eq 0
      end

      it "is one after it won" do
        subject.won
        expect(subject.win_percentage).to eq 1
      end

      it "is 0.5 after a win and a los" do
        subject.won
        subject.lost
        expect(subject.win_percentage).to be_within(0.01).of 0.5
      end

      it "is 0.33 after a win and two losses" do
        subject.won
        subject.lost
        subject.lost
        expect(subject.win_percentage).to be_within(0.01).of 0.33
      end
    end

    def create_test_node(wins, visits, parent)
      node = Node.new game_state, move, parent
      wins.times do node.won end
      (visits - wins).times do node.lost end
      node
    end

    describe '#uct_value' do
      it "gets the uct value right" do
        parent = create_test_node(0, 40, nil)
        node = create_test_node(5, 7, parent)
        expect(node.uct_value).to be_within(0.01).of 2.166
      end
    end

    describe '#uct_select_child' do
      it "selects the right child" do
        parent = create_test_node 0, 30, nil
        child_1 = create_test_node(0, 15, parent)
        child_2 = create_test_node(5, 7, parent)
        child_3 = create_test_node(4, 8, parent)
        allow(parent).to receive(:children).and_return [child_1, child_2, child_3]
        expect(parent.uct_select_child).to be child_2
      end
    end

    describe '#expand' do
      let(:game_state) {double('game_state', dup: dupped,
                                             all_valid_moves: [move_2]).as_null_object}
      let(:dupped) do
        mine = double('dupped').as_null_object
      end
      let(:move) {double 'move'}
      let(:move_2) {double 'move_2'}
      let(:node) {Node.new game_state, move, root}

      it "returns the child of the node" do
        expect(node.expand.parent).to be node
      end

      it "leads to no untried_moves" do
        node.expand
        expect(node).not_to be_untried_moves
      end

      it "the child has the one previously untried move as move" do
        child = node.expand
        expect(child.move).to be move_2
      end

      it "the child is in the children of the parent node" do
        child = node.expand
        expect(node.children).to eq [child]
      end

    end

    describe '#backpropagate' do
      let!(:child_1) {create_test_node(2, 4, root)}
      let!(:child_2) {create_test_node 1, 3, root}
      let!(:child_1_1) {create_test_node 2, 3, child_1}
      let!(:child_1_2) {create_test_node 0, 1, child_1}

      before :each do
        3.times do root.won end
        4.times do root.lost end
      end

      describe "winning at child_1_1" do

        before :each do
          child_1_1.backpropagate true
        end

        it "updates the node itself" do
          expect(child_1_1.wins).to eq 3
          expect(child_1_1.visits).to eq 4
        end

        it "results in a loss for the parent" do
          expect(child_1.wins).to eq 2
          expect(child_1.visits).to eq 5
        end

        it "results in a loss in the root (root accumulates level beneath it)" do
          expect(root.wins).to eq 3
          expect(root.visits).to eq 8
        end

        it "does not touch its own sibiling" do
          expect(child_1_2.visits).to eq 1
        end

        it "does nto touch its parents sibiling" do
          expect(child_2.visits).to eq 3
        end
      end

      describe 'winning child_1_2_1 gets a loss in the root' do
        let!(:child_1) {create_test_node(2, 4, root)}
        let!(:child_2) {create_test_node 1, 3, root}
        let!(:child_1_1) {create_test_node 2, 2, child_1}
        let!(:child_1_2) {create_test_node 1, 2, child_1}
        let!(:child_1_2_1) {create_test_node(0, 1, child_1_2)}

        before :each do
          child_1_2_1.backpropagate true
        end

        it "updates the node itself" do
          expect(child_1_2_1.wins).to eq 1
          expect(child_1_2_1.visits).to eq 2
        end

        it "propagates the change to its parent as a loss" do
          expect(child_1_2.wins).to eq 1
          expect(child_1_2.visits).to eq 3
        end

        it "propagates the change to the parent's parent as a win" do
          expect(child_1.wins).to eq 3
          expect(child_1.visits).to eq 5
        end

        it "propagates the change to the root as a win" do
          expect(root.wins).to eq 4
          expect(root.visits).to eq 8
        end

      end

    end
  end
end
