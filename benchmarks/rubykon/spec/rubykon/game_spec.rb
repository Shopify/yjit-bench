require_relative 'spec_helper'

module Rubykon
  RSpec.describe Rubykon::Game do
    let(:game) {described_class.new}
    let(:validator) {MoveValidator.new}

    context 'creation' do
      subject {game}
      it {is_expected.not_to be_nil}

      it 'has a default size of 19' do
        expect(game.board.size).to eq(19)
      end

      it 'has a move_count of 0' do
        expect(game.move_count).to eq 0
      end

      it 'has no moves playd' do
        expect(game).to be_no_moves_played
      end

      it 'can be created with another size' do
        size = 13
        expect(Rubykon::Game.new(size).board.size).to eq size
      end

      it 'can retrieve the board' do
        expect(game.board).not_to be_nil
      end
    end

    describe "next_turn_color" do
      it "is black for starters" do
        expect(game.next_turn_color).to eq Board::BLACK
      end

      it "is white after a black move" do
        game.play! *StoneFactory.build(color: Board::BLACK)
        expect(game.next_turn_color).to eq Board::WHITE
      end

      it "is black again after a white move" do
        game.play! *StoneFactory.build(color: Board::BLACK)
        game.play! *StoneFactory.build(x: 4, y: 5, color: Board::WHITE)
        expect(game.next_turn_color).to eq Board::BLACK
      end
    end

    describe "#finished?" do
      it "an empty game is not over" do
        expect(game).not_to be_finished
      end

      it "a game with one pass is not over" do
        game.play! *StoneFactory.pass(:black)
        expect(game).not_to be_finished
      end

      it "a game with two passes is over" do
        game.play! *StoneFactory.pass(:black)
        game.play! *StoneFactory.pass(:white)
        expect(game).to be_finished
      end
    end

    describe ".from" do
      let(:string) do
        <<-GAME
 X . . . O
 . . X . .
 X . . . .
 . . . . .
 . X . . O
        GAME
      end

      let(:new_game)  {Game.from string}
      let(:board)     {new_game.board}
      let(:group_tracker) {new_game.group_tracker}

      it "sets the right number of moves" do
        expect(new_game.move_count).to eq 6
      end

      it "assigns the stones a group" do
        expect(group_from(1, 1)).not_to be_nil
      end

      it "does not assign a group to the empty fields" do
        expect(group_tracker.stone_to_group).not_to have_key(board.identifier_for(2, 2))
      end

      it "has stones in all the right places" do
        expect(board_at(1, 1)).to eq :black
        expect(board_at(5, 1)).to eq :white
        expect(board_at(3, 2)).to eq :black
        expect(board_at(1, 3)).to eq :black
        expect(board_at(2, 5)).to eq :black
        expect(board_at(5, 5)).to eq :white
        expect(board_at(2, 2)).to eq Board::EMPTY
        expect(board_at(1, 4)).to eq Board::EMPTY
      end
    end

    describe 'playing moves' do

      let(:game) {Game.from board_string}
      let(:board) {game.board}
      let(:group_tracker) {game.group_tracker}

      describe 'play!' do
        let(:game) {Game.new 5}

        it "plays moves" do
          game.play!(2, 2, :black)
          expect(board_at(2, 2)).to eq :black
        end

        it "raises if the move is invalid" do
          expect do
            game.play!(0, 0, :black)
          end.to raise_error(IllegalMoveException)
        end
      end

      describe 'capturing stones' do
        let(:captures) {game.captures}
        let(:identifier) {board.identifier_for(capturer[0], capturer[1])}
        let(:color) {capturer.last}


        before :each do
          game.set_valid_move identifier, color
        end

        describe 'simple star capture' do
          let(:board_string) do
            <<-BOARD
 . . .
 X O X
 . X .
            BOARD
          end
          let(:capturer) {[2, 1, :black]}

          it "removes the captured stone from the board" do
            expect(board_at(2,2)).to eq Board::EMPTY
          end

          it "the stone made one capture" do
            expect(game.captures[:black]).to eq 1
          end

          it_behaves_like "has liberties at position", 2, 1, 3
          it_behaves_like "has liberties at position", 1, 2, 3
          it_behaves_like "has liberties at position", 2, 3, 3
          it_behaves_like "has liberties at position", 3, 2, 3
        end

        describe 'turtle capture' do
          let(:board_string) do
            <<-BOARD
 . . . . .
 . O O . .
 O X X . .
 . O O O .
 . . . . .
            BOARD
          end
          let(:capturer) {[4, 3, :white]}

          it "removes the two stones from the board" do
            expect(board_at(2, 3)).to eq Board::EMPTY
            expect(board_at(3, 3)).to eq Board::EMPTY
          end

          it "the board looks cleared afterwards" do
            expect(board.to_s).to eq <<-BOARD
 . . . . .
 . O O . .
 O . . O .
 . O O O .
 . . . . .
            BOARD
          end

          it "has 2 captures" do
            expect(captures[:white]).to eq 2
          end

          it "black can move into that space again (left)" do
            force_next_move_to_be :black, game
            should_be_valid_move [2, 3, :black], game
          end

          it "black can move into that space again (right)" do
            force_next_move_to_be :black, game
            should_be_valid_move [3, 3, :black], game
          end

          it_behaves_like "has liberties at position", 1, 3, 3
          it_behaves_like "has liberties at position", 2, 2, 6
          it_behaves_like "has liberties at position", 4, 3, 9

          describe "black playing left in the space" do
            before :each do
              force_next_move_to_be :black, game
              game.play! 2, 3, :black
            end

            it_behaves_like "has liberties at position", 2, 3, 1
            it_behaves_like "has liberties at position", 1, 3, 2
            it_behaves_like "has liberties at position", 2, 2, 5
            it_behaves_like "has liberties at position", 2, 4, 8
          end

          describe "black playing right in the space" do 
            before :each do
              force_next_move_to_be :black, game
              game.play! 3, 3, :black
            end

            it_behaves_like "has liberties at position", 3, 3, 1
            it_behaves_like "has liberties at position", 1, 3, 3
            it_behaves_like "has liberties at position", 2, 2, 5
            it_behaves_like "has liberties at position", 2, 4, 8
          end
        end

        describe 'capturing two distinct groups' do
          let(:board_string) do
            <<-BOARD
 . . . . .
 O O . O O
 X X . X X
 O O . O O
 . . . . .
            BOARD
            let(:capturer) {[3, 3, :white]}

            it "makes 4 captures" do
              expect(captures[:white]).to eq 4
            end

            it "removes the captured stones" do
              [board_at(1, 3), board_at(2, 3),
              board_at(4, 3), board_at(5, 3)].each do |field|
                expect(field).to eq Board::EMPTY
              end
            end

            it_behaves_like "has liberties at position", 1, 2, 5
            it_behaves_like "has liberties at position", 3, 2, 5
            it_behaves_like "has liberties at position", 3, 3, 4
            it_behaves_like "has liberties at position", 1, 4, 5
            it_behaves_like "has liberties at position", 3, 4, 5

          end
        end
      end

      describe 'Playing moves on a board (old board move integration)' do
        let(:game) {Game.new board_size}
        let(:board) {game.board}
        let(:board_size) {19}
        let(:simple_x) {1}
        let(:simple_y) {1}
        let(:simple_color) {:black}

        describe 'A simple move' do

          before :each do
            game.play! simple_x, simple_y, simple_color
          end

          it 'lets the board retrieve the move at that position' do
            expect(board_at(simple_x, simple_y)).to eq simple_color
          end

          it 'sets the move_count to 1' do
            expect(game.move_count).to eq 1
          end

          it 'should have played moves' do
            expect(game).not_to be_no_moves_played
          end

          it 'returns a truthy value' do
            legal_move = StoneFactory.build x: simple_x + 2, color: :white
            expect(game.play(*legal_move)).to eq(true)
          end

          it "can play a pass move" do
            pass = StoneFactory.pass(:white)
            expect(game.play *pass).to be true
          end
        end

        describe 'A couple of moves' do
          let(:moves) do
            [ StoneFactory.build(x: 3, y: 7, color: :black),
              StoneFactory.build(x: 5, y: 7, color: :white),
              StoneFactory.build(x: 3, y: 10, color: :black)
            ]
          end

          before :each do
            moves.each {|move| game.play *move}
          end

          it 'sets the move_count to the number of moves played' do
            expect(game.move_count).to eq moves.size
          end
        end

        describe 'Illegal moves' do
          it 'is illegal to play moves with a greater x than the board size' do
            illegal_move = StoneFactory.build(x: board_size + 1)
            expect(game.play(*illegal_move)).to eq(false)
          end

          it 'is illegal to play moves with a greater y than the board size' do
            illegal_move = StoneFactory.build(y: board_size + 1)
            expect(game.play(*illegal_move)).to eq(false)
          end
        end
      end
    end

    describe '#dup' do

      let(:dupped) {game.dup}
      let(:move1) {StoneFactory.build(x: 1, y:1, color: :black)}
      let(:move2) {StoneFactory.build x: 3, y:1, color: :white}
      let(:move3) {StoneFactory.build x: 5, y:1, color: :black}
      let(:board) {game.board}

      before :each do
        dupped.play! *move1
        dupped.play! *move2
        dupped.play! *move3
      end

      describe "empty game" do
        let(:game) {Game.new 5}

        it "does not change the board" do
          expect(board.to_s).to eq <<-BOARD
 . . . . .
 . . . . .
 . . . . .
 . . . . .
 . . . . .
          BOARD
        end

        it "has zero moves played" do
          expect(game.move_count).to eq 0
        end

        it "changes the board for the copy" do
          expect(dupped.board.to_s).to eq <<-BOARD
 X . O . X
 . . . . .
 . . . . .
 . . . . .
 . . . . .
          BOARD
        end

        it "has moves played for the copy" do
          expect(dupped.move_count).to eq 3
        end
      end

      describe "game with some moves" do
        let(:game) do
          Game.from board_string
        end
        let(:board_string) do
          <<-BOARD
 . . . . .
 O . X . X
 O . O . O
 . . . . .
 . . . . .
          BOARD
        end
        let(:group_tracker) {game.group_tracker}
        let(:dupped_tracker) {dupped.group_tracker}
        let(:identifier_5_2) {board.identifier_for(5, 2)}

        describe "not changing the original" do
          it "is still the same board" do
            expect(game.board.to_s).to eq board_string
          end

          it "still has the old move_count" do
            expect(game.move_count).to eq 6
          end

          it "does not modify the group of the stones" do
            expect(group_from(5, 2).stones.size).to eq 1
          end

          it "color at same position can be different" do
            expect(board_at(5,1)).not_to eq from_board_at(dupped.board, 5, 1)
          end

          it "the group points to the right liberties" do
            identifier_5_1 = board.identifier_for(5, 1)
            expect(group_from(5, 2).liberties.fetch(identifier_5_1)).to eq Board::EMPTY
            dupped_5_2_group = dupped_tracker.group_of(identifier_5_2)
            expect(dupped_5_2_group.liberties).not_to have_key(identifier_5_1)
          end

          it "does not register the new stones" do
            group = group_from(1, 2)
            expect(group.liberties.fetch(board.identifier_for(1, 1))).to eq Board::EMPTY
            expect(group.liberty_count).to eq 4
          end
        end

        describe "the dupped entity has the changes" do

          let(:group) {dupped_tracker.group_of(identifier_5_2)}

          it "has a move count of 9" do
            expect(dupped.move_count).to eq 9
          end

          it "has the new moves" do
            expect(dupped.board.to_s).to eq <<-BOARD
 X . O . X
 O . X . X
 O . O . O
 . . . . .
 . . . . .
            BOARD
          end

          it "handles groups" do
            expect(group.stones.size).to eq 2
          end

          it "has the right group liberties" do
            expect(group.liberties.fetch(board.identifier_for(4, 2))).to eq Board::EMPTY
            identifier = board.identifier_for(5, 3)
            group_id = dupped_tracker.group_id_of(identifier)
            expect(group.liberties[identifier]).to eq group_id
          end

          it "registers new stones" do
            group                = dupped_tracker.group_of(board.identifier_for(1, 2))
            identifier_1_1 = board.identifier_for(1, 1)
            expect(group.liberties.fetch(identifier_1_1)).to eq dupped_tracker.group_id_of(identifier_1_1)
            expect(group.liberty_count).to eq 3
          end
        end

      end
    end

    describe 'regressions' do
      describe 'weird missing liberties' do
        let(:game) {Game.new}
        let(:board) {game.board}
        let(:moves) do
          [[223, :black], [251, :white], [312, :black], [175, :white], [115, :black], [326, :white], [337, :black], [98, :white], [206, :black], [255, :white], [50, :black], [129, :white], [344, :black], [41, :white], [275, :black], [17, :white], [194, :black], [348, :white], [8, :black], [333, :white], [226, :black], [163, :white], [342, :black], [82, :white], [15, :black], [61, :white], [358, :black], [249, :white], [134, :black], [77, :white], [215, :black], [55, :white], [14, :black], [47, :white], [102, :black], [261, :white], [196, :black], [153, :white], [86, :black], [110, :white], [188, :black], [260, :white], [10, :black], [277, :white], [85, :black], [92, :white], [142, :black], [119, :white], [20, :black], [307, :white], [285, :black], [76, :white], [325, :black], [286, :white], [244, :black], [48, :white], [243, :black], [140, :white], [252, :black], [357, :white], [78, :black], [310, :white], [339, :black], [158, :white], [302, :black], [355, :white], [259, :black], [108, :white], [65, :black], [31, :white], [349, :black], [356, :white], [187, :black], [318, :white], [317, :black], [271, :white], [208, :black], [247, :white], [182, :black], [330, :white], [238, :black], [220, :white], [293, :black], [23, :white], [193, :black], [128, :white], [43, :black], [311, :white], [107, :black], [218, :white], [227, :black], [351, :white], [323, :black], [30, :white], [316, :black], [121, :white], [18, :black], [276, :white], [132, :black], [75, :white], [161, :black], [168, :white], [272, :black], [79, :white], [137, :black], [209, :white], [336, :black], [253, :white], [57, :black], [63, :white], [246, :black], [174, :white], [87, :black], [83, :white], [33, :black], [54, :white], [234, :black], [169, :white], [262, :black], [89, :white], [343, :black], [322, :white], [125, :black], [228, :white], [186, :black], [141, :white], [100, :black], [151, :white], [155, :black], [224, :white], [122, :black], [353, :white], [217, :black], [211, :white], [265, :black], [280, :white], [4, :black], [324, :white], [314, :black], [60, :white], [112, :black], [12, :white], [266, :black], [219, :white], [6, :black], [292, :white], [162, :black], [279, :white], [210, :black], [64, :white], [28, :black], [148, :white], [69, :black], [106, :white], [334, :black], [327, :white], [321, :black], [338, :white], [46, :black], [73, :white], [281, :black], [29, :white], [296, :black], [191, :white], [350, :black], [284, :white], [95, :black], [5, :white], [213, :black], [222, :white], [154, :black], [164, :white], [21, :black], [133, :white], [221, :black], [167, :white], [38, :black], [360, :white], [13, :black], [67, :white], [19, :black], [239, :white], [214, :black], [256, :white], [9, :black], [2, :white], [190, :black], [99, :white], [53, :black], [305, :white], [295, :black], [16, :white], [72, :black], [308, :white], [240, :black], [335, :white], [195, :black], [143, :white], [236, :black], [149, :white], [212, :black], [254, :white], [301, :black], [282, :white], [172, :black], [199, :white], [319, :black], [264, :white], [200, :black], [147, :white], [178, :black], [231, :white], [62, :black], [130, :white], [294, :black], [304, :white], [152, :black], [273, :white], [71, :black], [139, :white], [68, :black], [80, :white], [202, :black], [216, :white], [300, :black], [116, :white], [138, :black], [181, :white], [27, :black], [166, :white], [303, :black], [204, :white], [329, :black], [315, :white], [177, :black], [248, :white], [3, :black], [309, :white], [51, :black], [328, :white], [32, :black], [298, :white], [93, :black], [0, :white], [105, :black], [118, :white], [136, :black], [245, :white], [159, :black], [37, :white], [267, :black], [81, :white], [291, :black], [49, :white], [347, :black], [88, :white], [274, :black], [120, :white], [173, :black], [278, :white], [359, :black], [131, :white], [345, :black], [263, :white], [306, :black], [35, :white], [233, :black], [70, :white], [257, :black], [189, :white], [288, :black], [103, :white], [287, :black], [74, :white], [242, :black], [225, :white], [24, :black], [42, :white], [297, :black], [84, :white], [299, :black], [235, :white], [66, :black], [160, :white], [58, :black], [332, :white], [305, :black], [340, :white], [22, :black], [124, :white], [96, :black], [258, :white], [39, :black], [270, :white], [232, :black], [146, :white], [11, :black], [31, :white], [90, :black], [230, :white], [170, :black], [250, :white], [45, :black], [135, :white], [67, :black], [59, :white], [49, :black], [26, :white], [201, :black], [289, :white], [12, :black], [180, :white], [192, :black], [156, :white], [334, :black], [40, :white], [269, :black], [117, :white], [203, :black], [150, :white], [184, :black], [165, :white], [315, :black], [123, :white], [94, :black], [113, :white], [198, :black], [331, :white], [354, :black], [132, :white], [341, :black], [29, :white], [161, :black], [197, :white], [229, :black], [30, :white], [7, :black], [268, :white], [109, :black], [191, :white], [350, :black], [210, :white], [357, :black], [76, :white], [34, :black], [179, :white], [189, :black], [355, :white], [126, :black], [313, :white], [97, :black], [171, :white], [47, :black]]
        end

        before :each do
          moves.each do |identifier, color|
            game.play! *board.x_y_from(identifier), color
          end
        end

        it "does not allow the suicide move" do
          expect(MoveValidator.new.valid?(5, :white, game)).to be_falsey
        end

        it "has the right liberty)count for the neighboring group" do
          expect(game.group_tracker.group_of(4).liberty_count).to eq 3
        end

      end
    end

  end
end
