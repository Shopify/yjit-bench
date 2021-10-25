require_relative '../lib/rubykon'
require_relative 'support/playout_help'
require_relative 'support/benchmark-ips'

class Rubykon::GameScorer
  public :score_empty_cutting_point
  public :find_candidate_color
  public :only_one_color_adjacent?
end

Benchmark.ips do |benchmark|

  board = Rubykon::Board.from <<-BOARD
OOOOO-O-OOOOOOXXXXX
O-OOOOOO-O-OOOX-X-X
OO-OOXOXOOOO-OOXXXX
-OOOXXXXXXOOOOOX-X-
OOOOOXOXXXOOOOOOXXX
OXXOOOOOXOOOO-OOOOX
X-XOOOXXXOOOOOO-OOO
XXXOXXXOXXOOOOOOO-O
XX-XXXOOOOO-OOO-OOO
X-XXXXOXXO-OOOOOOOO
-XXXXXXXXXO-OOO-OOO
XXXX-X-XXXXOOXOO-O-
XX-XX-XX-XOOXXOOOOO
-XXXXX-XXXXOX-XOOOO
XXX-XXXXXXXXXXXXOXO
XXXX-XXXXX-X-XXXOXO
-XXXX-X-XXXXXXXXXXO
X-XX-XXXX-X-XX-XOOO
-XXXXX-XXXXXXXXXO-O
  BOARD
  scorer = Rubykon::GameScorer.new
  identifier = board.identifier_for(3, 3)



  benchmark.report 'score_empty_cp' do
    game_score = {Rubykon::Board::BLACK => 0,
                  Rubykon::Board::WHITE => Rubykon::Game::DEFAULT_KOMI}
    scorer.score_empty_cutting_point(identifier, board, game_score)
  end

  benchmark.report 'Board#neighbour_colors_of' do
    board.neighbour_colors_of(identifier)
  end

  neighbour_colors = board.neighbour_colors_of(identifier)

  benchmark.report 'find_candidate_color' do
    scorer.find_candidate_color(neighbour_colors)
  end

  candidate_color = scorer.find_candidate_color(neighbour_colors)

  benchmark.report 'only_one_c_adj?' do
    scorer.only_one_color_adjacent?(neighbour_colors, candidate_color)
  end
end
