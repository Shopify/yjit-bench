require_relative 'spec_helper'

module Rubykon
  RSpec.describe EyeDetector do
    subject{described_class.new}

    describe "obviously not eyes" do
      let(:board) {Board.new 5}


      it "is false for an empty cutting point" do
        expect_no_eye(3, 3, board)
      end

      it "is false for an empty cutting point at the edge" do
        expect_no_eye 3, 1, board
      end

      it "is false for the corner" do
        expect_no_eye 1, 1, board
      end

      it "is false when one of the star shapes is another color" do
        board = Board.from <<-BOARD
 . X .
 X . X
 . O .
        BOARD
        expect_no_eye 2, 2, board
      end
    end

    describe "false eyes" do

      it "is false when two diagonals are occupied by the enemy" do
        board = Board.from <<-BOARD
 . . . . .
 . . X O .
 . X . X .
 . . X O .
 . . . . .
        BOARD
        expect_no_eye 3, 3, board
      end

      it "is false when two diagonals are occupied by the enemy (diagonal)" do
        board = Board.from <<-BOARD
 . . . . .
 . . X O .
 . X . X .
 . O X . .
 . . . . .
        BOARD
        expect_no_eye 3, 3, board
      end

      it "is false when three diagonals are occupied by the enemy" do
        board = Board.from <<-BOARD
 . . . . .
 . O X O .
 . X . X .
 . . X O .
 . . . . .
        BOARD
        expect_no_eye 3, 3, board
      end

      it "is false when four diagonals are occupied by the enemy" do
        board = Board.from <<-BOARD
 . . . . .
 . O X O .
 . X . X .
 . O X O .
 . . . . .
        BOARD
        expect_no_eye 3, 3, board
      end

      it "is false on the edge when just one diagonal is occupied" do
        board = Board.from <<-BOARD
 . X . X .
 . . X O .
 . . . . .
 . . . . .
 . . . . .
        BOARD
        expect_no_eye 3, 1, board
      end

      it "is false in the corner with the diagonal occupied" do
        board = Board.from <<-BOARD
 . X .
 X O .
 . . .
        BOARD
        expect_no_eye 1, 1, board
      end

    end

    describe "real eyes" do

      it "is real for a star shape" do
        board = Board.from <<-BOARD
 . X .
 X . X
 . X .
        BOARD
        expect_eye 2, 2, board
      end

      it "is real for a star shape with one diagonal occupied by enemy" do
        board = Board.from <<-BOARD
 . . . . .
 . . X O .
 . X . X .
 . . X . .
 . . . . .
        BOARD
        expect_eye 3, 3, board
      end

      it "is real on the edge" do
        board = Board.from <<-BOARD
 X . X
 . X .
 . . .
        BOARD
        expect_eye 2, 1, board
      end

      it "is real in the corner" do
        board = Board.from <<-BOARD
 . X .
 X . .
 . . .
        BOARD
        expect_eye 1, 1, board
      end

    end

    def expect_eye(x, y, board)
      expect(subject.is_eye?(board.identifier_for(x, y), board)).to be_truthy
    end

    def expect_no_eye(x, y, board)
      expect(subject.is_eye?(board.identifier_for(x, y), board)).to be_falsey
    end
  end
end
