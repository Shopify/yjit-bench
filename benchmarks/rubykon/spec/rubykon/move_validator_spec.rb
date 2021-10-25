require_relative 'spec_helper'

module Rubykon
  describe MoveValidator do

    let(:validator) {MoveValidator.new}
    let(:board_size) {19}
    let(:game) {Game.new board_size}
    let(:baord) {game.board}

    it 'can be created' do
      expect(validator).not_to be_nil
    end

    describe 'legal moves' do
      it 'is accepts normal moves' do
        should_be_valid_move StoneFactory.build, game
      end

      it 'accepts 1-1' do
        should_be_valid_move (StoneFactory.build x: 1, y: 1), game
      end

      it 'accepts the move in the top right corner (19-19)' do
        should_be_valid_move StoneFactory.build(x: board_size,
                                                         y: board_size),
                              game
      end

      it 'accepts a different color after the first move was played' do
        game.play! *StoneFactory.build(color: :black, x: 1, y: 1)
        should_be_valid_move (StoneFactory.build color: :white), game
      end

      it 'also works correctly with bigger boards' do
        game = Game.new 37
        should_be_valid_move (StoneFactory.build x: 37, y: 37), game
      end

      it "allows for pass moves" do
        should_be_valid_move StoneFactory.pass, game
      end
    end

    describe 'Moves illegal of their own' do
      it 'is illegal with negative x and y' do
        move = StoneFactory.build x: -3, y: -4
        should_be_invalid_move move, game
      end

      it 'is illegal with negative x' do
        move = StoneFactory.build x: -1
        should_be_invalid_move move, game
      end

      it 'is illegal with negative y' do
        move = StoneFactory.build y: -1
        should_be_invalid_move move, game
      end

      it 'is illegal with x set to 0' do
        move = StoneFactory.build x: 0
        should_be_invalid_move move, game
      end

      it 'is illegal with y set to 0' do
        move = StoneFactory.build y: 0
        should_be_invalid_move move, game
      end
    end

    describe 'Moves illegal in the context of a board' do
      it 'is illegal with x bigger than the board size' do
        move = StoneFactory.build x: board_size + 1
        should_be_invalid_move move, game
      end

      it 'is illegal with y bigger than the board size' do
        move = StoneFactory.build y: board_size + 1
        should_be_invalid_move move, game
      end

      it 'is illegal to set a stone at a position already occupied by a stone' do
        move = StoneFactory.build x: 1, y: 1
        game.play *move
        should_be_invalid_move move, game
      end

      it 'also works for other board sizes' do
        game = Game.new 5
        should_be_invalid_move (StoneFactory.build x: 6), game
      end
    end

    describe 'suicide moves' do
      it "is forbidden" do
        game = Game.from <<-BOARD
 . X .
 X . X
 . X .
        BOARD
        force_next_move_to_be :white, game
        should_be_invalid_move [2, 2, :white], game
      end

      it "is forbidden in the corner as well" do
        game = Game.from <<-BOARD
 . X .
 X . .
 . . .
        BOARD
        force_next_move_to_be :white, game
        should_be_invalid_move [1, 1, :white], game
      end

      it "is forbidden when it robs a friendly group of its last liberty" do
        game = Game.from <<-BOARD
 O X . .
 O X . .
 O X . .
 . X . .
        BOARD
        force_next_move_to_be :white, game
        should_be_invalid_move [1, 4, :white], game
      end

      it "is valid if the group still has liberties with the move" do
        game = Game.from <<-BOARD
 O X . .
 O X . .
 O X . .
 . . . .
        BOARD
        force_next_move_to_be :white, game
        should_be_valid_move [1, 4, :white], game
      end

      it "is valid if it captures the group" do
        game = Game.from <<-BOARD
 O X O .
 O X O .
 O X O .
 . X O .
        BOARD
        force_next_move_to_be :white, game
        should_be_valid_move [1, 4, :white], game
      end

      it "is allowed when it captures a stone first (e.g. no suicide)" do
        game = Game.from <<-BOARD
 . . . .
 . X O .
 X . X O
 . X O .
        BOARD
        force_next_move_to_be :white, game
        should_be_valid_move [2, 3, :white], game
      end
    end

    describe 'KO' do

      let(:game) {Game.from board_string}

      let(:board_string) do
        <<-BOARD
 . X O .
 X . X O
 . X O .
 . . . .
        BOARD
      end
      let(:white_ko_capture) {StoneFactory.build x: 2, y: 2, color: :white}
      let(:black_ko_capture) {StoneFactory.build x: 3, y: 2, color: :black}
      let(:black_tenuki) {StoneFactory.build x: 1, y: 4, color: :black}
      let(:white_closes) {StoneFactory.build x: 3, y: 2, color: :white}
      let(:white_tenuki) {StoneFactory.build x: 2, y: 4, color: :white}

      before :each do
        force_next_move_to_be :white, game
      end

      it 'is a valid move for white at 2-2' do
        should_be_valid_move white_ko_capture, game
      end

      describe "white caputres ko" do

        before :each do
          game.play! *white_ko_capture
        end

        it 'is an invalid move to catch back for black' do
          should_be_invalid_move black_ko_capture, game
        end
        
        it "black can tenuki" do
          should_be_valid_move black_tenuki, game
        end

        describe "black tenuki" do

          before :each do
            game.play! *black_tenuki
          end

          it "white can close the ko" do
            should_be_valid_move white_closes, game
          end
          
          it "white can tenuki" do
            should_be_valid_move white_tenuki, game
          end

          describe "white tenuki" do
            before :each do
              game.play! *white_tenuki
            end
            
            it "black can capture" do
              should_be_valid_move black_ko_capture, game
            end
          end
        end
      end

    end

    describe "double move" do
      it "is not valid for the same color to move two times" do
        move_1 = StoneFactory.build x: 2, y: 2, color: :black
        move_2 = StoneFactory.build x: 1, y: 1, color: :black
        game.play! *move_1
        should_be_invalid_move move_2, game
      end
    end

  end
end
