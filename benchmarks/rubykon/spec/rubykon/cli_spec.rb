require_relative 'spec_helper'
require 'stringio'

module Rubykon
  RSpec.describe CLI do
    subject {described_class.new}
    context 'stubbed out MCTS' do
      let(:fake_root) {double 'fake_root', best_move: [33, :black],
                                           children: children}
      let(:children) do
        (0..9).map {double 'child', move: [33, :black], win_percentage: 0.5}
      end

      before :each do
        allow_any_instance_of(MCTS::MCTS).to receive(:start).and_return(fake_root)
      end

      describe 'choosing a board' do
        # input has to go in before starting, otherwise we are stuck waiting
        it "displays a message prompting the user to choose a game type" do
          output = FakeIO.each_input ['exit'] do
            subject.start
          end

          expect(output).to match /board size/
          expect(output).to match /9.*13.*19/
        end

        it "waits for some input of a board size" do
          output = FakeIO.each_input %w(9 100 exit) do
            subject.start
          end
          expect(output).to match /starting.*9x9/
        end

        it "keeps prompting until a number was entered" do
          output = FakeIO.each_input %w(h9 19 100 exit) do
            subject.start
          end
          expect(output).to match /number.*try again/i
          expect(output).to match /starting/i
        end

        it "prints a board with nice labels" do
          output = FakeIO.each_input %w(19 100 exit) do
            subject.start
          end

          nice_board = <<-BOARD
    A B C D E F G H J K L M N O P Q R S T
 19 . . . . . . . . . . . . . . . . . . . 19
 18 . . . . . . . . . . . . . . . . . . . 18
 17 . . . . . . . . . . . . . . . . . . . 17
 16 . . . . . . . . . . . . . . . . . . . 16
 15 . . . . . . . . . . . . . . . . . . . 15
 14 . . . . . . . . . . . . . . . . . . . 14
 13 . . . . . . . . . . . . . . . . . . . 13
 12 . . . . . . . . . . . . . . . . . . . 12
 11 . . . . . . . . . . . . . . . . . . . 11
 10 . . . . . . . . . . . . . . . . . . . 10
  9 . . . . . . . . . . . . . . . . . . .  9
  8 . . . . . . . . . . . . . . . . . . .  8
  7 . . . . . . . . . . . . . . . . . . .  7
  6 . . . . . . . . . . . . . . . . . . .  6
  5 . . . . . . . . . . . . . . . . . . .  5
  4 . . . . . . . . . . . . . . . . . . .  4
  3 . . . . . . . . . . . . . . . . . . .  3
  2 . . . . . . . . . . . . . . . . . . .  2
  1 . . . . . . . . . . . . . . . . . . .  1
    A B C D E F G H J K L M N O P Q R S T
          BOARD

          expect(output).to include nice_board
        end
      end

      describe 'enter playputs' do
        it "asks for the number of playouts" do
          output = FakeIO.each_input %w(9 1000 exit) do
            subject.start
          end
          expect(output).to match /number.*playouts/i
          expect(output).to match /1000 playout/i
        end
      end

      describe 'entering a move' do
        it "makes a whole test through all the things" do
          output = FakeIO.each_input %w(9 100 A9 exit) do
            subject.start
          end

          expect(output).to match /O . . . . . . . ./
          expect(output).to match /starting/i
        end

        it "can handle lower/uppercase case input" do
          output = FakeIO.each_input %w(9 100 a9 exit) do
            subject.start
          end

          expect(output).to match /O . . . . . . . ./
          expect(output).not_to match /invalid/i
        end

        it "rejects moves that are not on the board" do
          output = FakeIO.each_input %w(9 100 A10 A9 exit) do
            subject.start
          end

          expect(output).to match /invalid move/i
          expect(output).to match /O . . . . . . . ./
        end

        it "rejects moves that are set where there's only a move" do
          output = FakeIO.each_input %w(9 100 A9 A9 D9 exit) do
            subject.start
          end

          expect(output).to match /invalid move/i
          expect(output).to match /O . . O . . . . ./
        end

        it "doesn't blow up on invalid input" do
          output = FakeIO.each_input %w(9 100 adslkadla A9 exit) do
            subject.start
          end

          expect(output).to match /sorry/i
          expect(output).to match /O . . . . . . . ./
        end
      end
    end

    context 'real MCTS' do
      it "does not blow up (but we take a very small board" do
        output = FakeIO.each_input %w(2 100 B1 exit) do
          subject.start
        end

        expect(output).to match /thinking/
        expect(output).to match /black/
        expect(output).to match /white/
      end

      describe "wdyt" do
        it "prints the win percentages" do
          output = FakeIO.each_input %w(9 10 wdyt exit) do
            subject.start
          end

          expect(output).to match /\=> \d?\d\.\d\d*%/
        end
      end
    end
  end
end
