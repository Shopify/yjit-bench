require_relative '../lib/rubykon'
require_relative 'support/playout_help'
require_relative 'support/benchmark-ips'

class Rubykon::GameState
  public :plausible_move?
  public :next_turn_color
end

class Rubykon::EyeDetector
  public :candidate_eye_color
  public :is_real_eye?
end

class Rubykon::MoveValidator
  public :no_suicide_move?
end

class Rubykon::GroupTracker
  public :color_to_neighbour
  public :create_own_group
  public :take_liberties_of_enemies
  public :join_group_of_friendly_stones
  public :add_liberties
end


Benchmark.ips do |benchmark|
  empty_game = Rubykon::GameState.new Rubykon::Game.new 19
  mid_game = empty_game.dup
  200.times do
    mid_game.set_move mid_game.generate_move
  end
  finished_game = playout_for(19).game_state

  games = {
    empty_game    => 'empty game',
    mid_game      => 'mid game (200 moves played)',
    finished_game => 'finished game'
  }

  games.each do |game_state, description|

    game = game_state.game
    board = game.board

    benchmark.report "#{description}: finished?" do
      game_state.finished?
    end

    benchmark.report "#{description}: generate_move" do
      game_state.generate_move
    end

    color = game_state.next_turn_color

    benchmark.report "#{description}: plausible_move?" do
      identifier = rand(361)
      game_state.plausible_move?(identifier, color)
    end

    validator    = Rubykon::MoveValidator.new

    benchmark.report "#{description}: valid?" do
      identifier = rand(361)
      validator.valid?(identifier, color, game)
    end

    benchmark.report "#{description}: no_suicide_move?" do
      identifier = rand(361)
      validator.no_suicide_move?(identifier, color, game)
    end

    eye_detector = Rubykon::EyeDetector.new

    benchmark.report "#{description}: is_eye?" do
      identifier = rand(361)
      eye_detector.is_eye?(identifier, board)
    end

    benchmark.report "#{description}: candidate_eye_color" do
      identifier = rand(361)
      eye_detector.candidate_eye_color(identifier, board)
    end

    candidate_identifier = rand(361)
    candidate_eye_color = eye_detector.candidate_eye_color(candidate_identifier, board)

    benchmark.report "#{description}: is_real_eye?" do
      eye_detector.is_real_eye?(candidate_identifier, board, candidate_eye_color)
    end

    benchmark.report "#{description}: diagonal_colors_of" do
      identifier = rand(361)
      board.diagonal_colors_of(identifier)
    end

    benchmark.report "#{description}: dup" do
      game_state.dup
    end

    benchmark.report "#{description}: set_valid_move" do
      game.dup.set_valid_move rand(361), color
    end

    benchmark.report "#{description}: assign" do
      group_tracker = game.group_tracker.dup
      group_tracker.assign(rand(361), color, board)
    end

    group_tracker = game.group_tracker.dup

    benchmark.report "#{description}: color_to_neighbour" do
      group_tracker.color_to_neighbour(board, rand(361))
    end
  end


  # more rigorous setup, values gotta be right so we can't just take
  # our randomly played out boards. Also this doesn't make much sense
  # on the empty or finished board.

  game = Rubykon::Game.new(19)
  group_tracker = game.group_tracker

  stone1 = 55
  liberties_1 = {
    54 => Rubykon::Board::EMPTY,
    56 => 56,
    36 => Rubykon::Board::EMPTY,
    74 => Rubykon::Board::EMPTY,
    57 => Rubykon::Board::EMPTY
  }
  group_1 = Rubykon::Group.new(stone1, [stone1], liberties_1, 4)
  group_tracker.stone_to_group[55] = 1
  group_tracker.groups[1] = group_1
  group_tracker.create_own_group(56)

  stone2 = 33
  liberties_2 = {
    32 => Rubykon::Board::EMPTY,
    34 => 34,
    24 => Rubykon::Board::EMPTY,
    54 => Rubykon::Board::EMPTY,
    55 => Rubykon::Board::EMPTY
  }
  group_2 = Rubykon::Group.new(stone2, [stone2], liberties_2, 4)
  group_tracker.stone_to_group[33] = 2
  group_tracker.groups[2] = group_2
  group_tracker.create_own_group(34)

  # "small groups" as they have few liberties and stones assigned to them,
  # groups can easily have 20+ stones and even more liberties, but that'd
  # be even more setup :)
  benchmark.report 'connecting two small groups' do
    stones = [stone1, stone2]
    my_stone = 44
    group_tracker.dup.join_group_of_friendly_stones(stones, my_stone)
  end

  benchmark.report 'add_liberties' do
    liberties = [24, 78, 36, 79]
    group_tracker.add_liberties(liberties, stone1)
  end

  enemy_stones = [56, 34]
  liberties = {
    stone1 => stone1,
    23 => Rubykon::Board::EMPTY,
    73 => Rubykon::Board::EMPTY
  }
  enemy_group_1 = Rubykon::Group.new(enemy_stones[0], [enemy_stones[0]], liberties, 2)
  enemy_group_2 = Rubykon::Group.new(enemy_stones[1], [enemy_stones[1]], liberties.dup, 2)
  group_tracker.stone_to_group[enemy_stones[0]] = 3
  group_tracker.groups[3] = enemy_group_1

  group_tracker.stone_to_group[enemy_stones[1]] = 4
  group_tracker.groups[4] = enemy_group_2


  # Does not trigger enemy_group.caught? and removing the group.
  # That doesn't happen THAT often and it'd require to setup an according
  # board (with each test run)
  benchmark.report 'remove liberties of enemies' do

    group_tracker.dup.take_liberties_of_enemies(enemy_stones, stone1, game.board, :black)
  end
end
