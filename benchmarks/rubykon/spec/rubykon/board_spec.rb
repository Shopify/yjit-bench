require_relative 'spec_helper'
module Rubykon
  describe Board do

    let(:board) {Board.new(19)}

    context 'setting and retrieving LOOKUP' do
      it 'has the empty symbol for every LOOKUP' do
        all_empty = board.all? do |identifier, color|
          color == Board::EMPTY
        end
        expect(all_empty).to be true
      end

      it 'can retrive the empty values via #[]' do
        expect(board[1]).to eq Board::EMPTY
      end

      it "gives the initially set stones the right coordinates" do
        expect(board[board.identifier_for(1, 1)]).to eq Board::EMPTY
        expect(board[board.identifier_for(1, 7)]).to eq Board::EMPTY
        expect(board[board.identifier_for(7, 1)]).to eq Board::EMPTY
        expect(board[board.identifier_for(19, 19)]).to eq Board::EMPTY
        expect(board[board.identifier_for(3, 5)]).to eq Board::EMPTY
      end

      it 'can set values with []= and geht them with []' do
        board[34] = :test
        expect(board[34]).to be :test
      end

      it 'sets and gets with and without identifiers' do
        identifier = board.identifier_for(5, 7)
        board[identifier] = :special
        expect(board[identifier]).to eq :special
      end
    end

    describe "identifier conversion" do

      it "works fine on the first line" do
        expect(board.identifier_for(1, 1)).to eq 0
      end

      it "works fine at the last spot" do
        expect(board.identifier_for(19, 19)).to eq 360
      end

      it "is a reversible operation" do
        identifier = board.identifier_for(7, 9)
        expect(identifier).to eq 158
        x, y = board.x_y_from(identifier)
        expect(x).to eq 7
        expect(y).to eq 9
      end

      it "handles passing moves" do
        x, y, _color = StoneFactory.pass
        expect(board.identifier_for(x, y)).to eq nil
      end
    end

    describe "#neighbours_of and neighbour_colors_of" do
      it "returns the stones of the neighbouring fields" do
        board = Rubykon::Board.from <<-String
 . X .
 O . X
 . . .
        String
        identifier = board.identifier_for(2, 2)
        expect(board.neighbours_of(identifier)).to contain_exactly(
                                          [board.identifier_for(2, 1), :black],
                                          [board.identifier_for(3, 2), :black],
                                          [board.identifier_for(1, 2), :white],
                                          [board.identifier_for(2, 3), Board::EMPTY])
        expect(board.neighbour_colors_of(identifier)).to contain_exactly(
                                                    :black, :black, :white,
                                                    Board::EMPTY)
      end


      it "returns fewer stones when on the edge" do
        board = Rubykon::Board.from <<-String
 . . X
 . O .
 . . .
        String
        identifier = board.identifier_for(2, 1)
        expect(board.neighbours_of(identifier)).to contain_exactly(
                                            [board.identifier_for(3, 1), :black],
                                            [board.identifier_for(2, 2), :white],
                                            [board.identifier_for(1, 1), Board::EMPTY])
        expect(board.neighbour_colors_of(identifier)).to contain_exactly(
                                                     :black, :white,
                                                     Board::EMPTY)
      end

      it "on the other edge" do
        board = Rubykon::Board.from <<-String
 X . .
 . O .
 . . .
        String
        identifier = board.identifier_for(1, 2)
        expect(board.neighbours_of(identifier)).to contain_exactly(
                                            [board.identifier_for(1, 1), :black],
                                            [board.identifier_for(2, 2), :white],
                                            [board.identifier_for(1, 3), Board::EMPTY])
        expect(board.neighbour_colors_of(identifier)).to contain_exactly(
                                                     :black, :white,
                                                     Board::EMPTY)
      end


      it "returns fewer stones when in the corner" do
        board = Rubykon::Board.from <<-String
 . X .
 . . .
 . . .
        String
        identifier = board.identifier_for(1, 1)
        expect(board.neighbours_of(identifier)).to contain_exactly(
                                           [board.identifier_for(2, 1), :black],
                                           [board.identifier_for(1, 2), Board::EMPTY])
        expect(board.neighbour_colors_of(identifier)).to contain_exactly(
                                                     :black, Board::EMPTY)
      end
    end

    describe "#diagonal_colors_of" do
      it "returns the colors in the diagonal fields" do
        board = Board.from <<-BOARD
 O . X
 . . .
 X . .
        BOARD
        expect(board.diagonal_colors_of(board.identifier_for(2, 2))).to contain_exactly :white,
                                                                  :black,
                                                                  :black,
                                                                  Board::EMPTY
      end

      it "does not contain the neighbors" do
        board = Board.from <<-BOARD
 . X .
 O . X
 . O .
        BOARD
        expect(board.diagonal_colors_of(board.identifier_for(2, 2))).to contain_exactly Board::EMPTY,
                                                                  Board::EMPTY,
                                                                  Board::EMPTY,
                                                                  Board::EMPTY
      end

      it "works on the edge" do
        board = Board.from <<-BOARD
 . . .
 O . X
 . . .
        BOARD
        expect(board.diagonal_colors_of(board.identifier_for(2, 1))).to contain_exactly :white,
                                                                  :black
      end

      it "works on the edge 2" do
        board = Board.from <<-BOARD
 . X .
 . . .
 . O .
        BOARD
        expect(board.diagonal_colors_of(board.identifier_for(1, 2))).to contain_exactly :white,
                                                                  :black
      end

      it "works in the corner" do
        board = Board.from <<-BOARD
 . . .
 . X .
 . . .
        BOARD
        expect(board.diagonal_colors_of(board.identifier_for(1, 1))).to contain_exactly :black
      end
    end

    describe "on_edge?" do
      let(:board) {Board.new 5}

      it "is false for coordinates close to the edge" do
        expect(board.on_edge?(board.identifier_for(2, 2))).to be_falsey
        expect(board.on_edge?(board.identifier_for(4, 4))).to be_falsey
      end

      it "is true if one coordinate is 1" do
        expect(board.on_edge?(board.identifier_for(1, 3))).to be_truthy
        expect(board.on_edge?(board.identifier_for(2, 1))).to be_truthy
        expect(board.on_edge?(board.identifier_for(1, 1))).to be_truthy
      end

      it "is true if one coordinate is boardsize" do
        expect(board.on_edge?(board.identifier_for(2, 5))).to be_truthy
        expect(board.on_edge?(board.identifier_for(5, 1))).to be_truthy
        expect(board.on_edge?(board.identifier_for(5, 5))).to be_truthy
      end
    end

    describe '#==' do
      it "is true for two empty boards" do
        expect(Rubykon::Board.new(5) == Rubykon::Board.new(5)).to be true
      end

      it "is false when the board size is different" do
        expect(Rubykon::Board.new(6) == Rubykon::Board.new(5)).to be false
      end

      it "is equal to itself" do
        board = Rubykon::Board.new 5
        expect(board == board).to be true
      end

      it "is false if one of the boards has a move played" do
        board = Rubykon::Board.new 5
        other_board = Rubykon::Board.new 5
        board[1] = :muh
        expect(board == other_board).to be false
      end

      it "is true if both boards has a move played" do
        board = Rubykon::Board.new 5
        other_board = Rubykon::Board.new 5
        board[1] = :black
        other_board[1] = :black
        expect(board == other_board).to be true
      end

      it "is false if both boards have a move played but different colors" do
        board = Rubykon::Board.new 5
        other_board = Rubykon::Board.new 5
        board[1] = :white
        other_board[1] = :black
        expect(board == other_board).to be false
      end
    end

    describe '#String conversions' do
      let(:board) {Rubykon::Board.new 7}

      it "correctly outputs an empty board" do
        expected = <<-BOARD
 . . . . . . .
 . . . . . . .
 . . . . . . .
 . . . . . . .
 . . . . . . .
 . . . . . . .
 . . . . . . .
        BOARD

        board_string = board.to_s
        expect(board_string).to eq expected
        expect(Rubykon::Board.from board_string).to eq board
      end

      it "correctly outputs a board with a black move" do
        board[board.identifier_for(4, 4)] = :black
        expected = <<-BOARD
 . . . . . . .
 . . . . . . .
 . . . . . . .
 . . . X . . .
 . . . . . . .
 . . . . . . .
 . . . . . . .
        BOARD
        board_string = board.to_s
        expect(board_string).to eq expected
        expect(Rubykon::Board.from board_string).to eq board
      end

      it "correctly outputs a board with a white move" do
        board[board.identifier_for(4, 4)] = :white
        expected = <<-BOARD
 . . . . . . .
 . . . . . . .
 . . . . . . .
 . . . O . . .
 . . . . . . .
 . . . . . . .
 . . . . . . .
        BOARD
        board_string = board.to_s
        expect(board_string).to eq expected
        expect(Rubykon::Board.from board_string).to eq board
      end

      it "correctly outputs multiple moves played" do
        board[board.identifier_for(1, 1)] = :white
        board[board.identifier_for(7, 7)] = :black
        board[board.identifier_for(1, 7)] = :white
        board[board.identifier_for(7, 1)] = :black
        board[board.identifier_for(5, 5)] = :white
        board[board.identifier_for(3, 3)] = :black

        expected = <<-BOARD
 O . . . . . X
 . . . . . . .
 . . X . . . .
 . . . . . . .
 . . . . O . .
 . . . . . . .
 O . . . . . X
        BOARD
        board_string = board.to_s
        expect(board_string).to eq expected
        expect(Rubykon::Board.from board_string).to eq board
      end

      describe '.convert' do
        it "makes the conversion" do
          legacy = <<-BOARD
O-----X
-------
--X----
-------
----O--
-------
O-----X
          BOARD
          expect(Board.convert(legacy)).to eq <<-BOARD
 O . . . . . X
 . . . . . . .
 . . X . . . .
 . . . . . . .
 . . . . O . .
 . . . . . . .
 O . . . . . X
          BOARD
        end
      end

    end

  end
end