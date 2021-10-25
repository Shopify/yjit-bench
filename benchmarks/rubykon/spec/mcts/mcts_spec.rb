require_relative 'spec_helper'

module MCTS
  RSpec.describe MCTS do
    subject {MCTS.new }
    let(:double_step) {Examples::DoubleStep.new}
    let(:root) {subject.start(double_step, times)}
    let(:times) {100}

    it "returns the best move (2)" do
      expect(root.best_move).to eq 2
    end

    it "creates 2 children" do
      expect(root.children.size).to eq 2
    end

    it "made 1000 visits to the root" do
      expect(root.visits).to eq times
    end
  end
end
