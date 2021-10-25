require_relative 'spec_helper'

module Rubykon
  RSpec.describe GameScorer do
    let(:game) {Game.from board_string}
    let(:scorer) {described_class.new}
    let(:score) {scorer.score game}
    let(:black_score) {score[:black]}
    let(:white_score) {score[:white]}
    let(:winner) {score[:winner]}

    describe "empty board" do
      let(:game) {Game.new 9}

      it_behaves_like "correctly scored", :black => 0,
                                          :white => Game::DEFAULT_KOMI
    end

    describe "it correctly scores a tiny finished game" do

      let(:board_string) do
      <<-BOARD
 . X X O .
 X X O . O
 . X O O .
 X X O O O
 X X X X O
      BOARD
      end

      it_behaves_like "correctly scored", :black => 13,
                                          :white => 12 + Game::DEFAULT_KOMI

      it "gets the right winner" do
        expect(winner).to eq :white
      end
    end

    describe "it correctly scores a 9x9 board" do
      let(:board_string) do
        <<-BOARD
 . X X O . O . O O
 X . X O O . O O O
 X X O O . O X X X
 O X O . O O X X X
 O O O O O O X X X
 . O O X X X X O O
 O O X . X X X O .
 O X . X . X X O O
 O X X . X X X O .
        BOARD
      end

      it_behaves_like "correctly scored", :black => 39,
                                          :white => 42 + Game::DEFAULT_KOMI
    end

    describe "game won slightly by komi" do
      let(:board_string) do 9
        <<-BOARD
 . X X O . O . O O
 X . X O O . O O O
 X X O O . O X X X
 O X O . O O X X X
 O O O O O O X X X
 O O O X X X X O O
 X X X . X X X O .
 X X . X . X X O O
 X X X . X X X O .
        BOARD
      end

      it_behaves_like "correctly scored", :black => 43,
                                          :white => 38 + Game::DEFAULT_KOMI
      it "gets the right winner" do
        expect(winner).to eq :white
      end

      context "with a different komi" do
        before :each do
          game.komi = 0.5
        end

        it_behaves_like "correctly scored", :black => 43,
                                            :white => 38.5

        it "gets the right winner" do
          expect(winner).to eq :black
        end

      end

      context 'it takes prisoners into account' do
        let(:captures) {{black: 6, white: 4}}

        before :each do
          allow(game).to receive(:captures).and_return captures
        end

        it_behaves_like "correctly scored", :black => 43 + 6,
                                            :white => 38 + Game::DEFAULT_KOMI + 4

        it "gets the right winner" do
          expect(winner).to eq :black
        end
      end
    end

  end
end
