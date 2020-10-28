# Draws an empty board with no solutions.

require_relative 'lib/lee'

board_filename, output_filename, *rest = ARGV
raise 'no input filename' unless board_filename
raise 'no output filename' unless output_filename
raise 'too many arguments' unless rest.empty?

board = Lee.read_board(board_filename)
puts "routes: #{board.routes.size}"
Lee.draw board, [], output_filename
