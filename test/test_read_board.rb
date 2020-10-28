require 'minitest/autorun'

require_relative '../lib/lee'

class TestReadBoard < Minitest::Test
  def test_read_all_boards
    Dir.glob(File.join(__dir__, '..', 'inputs', '*.txt')).each do |board_filename|
      board = Lee.read_board(board_filename)
      assert board.pads.all? { |pad| Lee.point_on_board?(board, pad) }
      assert board.routes.all? { |route| Lee.route_on_board?(board, route) }
    end
  end

  def test_read_maon_board
    board = Lee.read_board(File.join(__dir__, '..', 'inputs', 'mainboard.txt'))
    assert board.pads.include?(Lee::Point.new(366, 554))
    assert board.routes.include?(Lee::Route.new(Lee::Point.new(280, 60), Lee::Point.new(280, 126)))
  end
end
