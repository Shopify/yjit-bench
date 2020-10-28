# Does a brute force solution not caring that pads are obstacles and not caring
# about cost.

require_relative 'lib/lee'

board_filename, output_filename, *rest = ARGV
raise 'no input filename' unless board_filename
raise 'too many arguments' unless rest.empty?

board = Lee.read_board(board_filename)

solutions = {}

board.routes.each do |route|
  solution = [route.a]

  x = route.a.x
  y = route.a.y

  step = route.b.x < x ? -1 : +1
  until x == route.b.x
    x += step
    solution.push Lee::Point.new(x, y)
  end

  step = route.b.y < y ? -1 : +1
  until y == route.b.y
    y += step
    solution.push Lee::Point.new(x, y)
  end

  solutions[route] = solution
end

raise 'invalid solution' unless Lee.solution_valid?(board, solutions)

cost, depth = Lee.cost_solutions(board, solutions)
puts "routes: #{board.routes.size}"
puts "cost:   #{cost}"
puts "depth:  #{depth}"

Lee.draw board, solutions.values, output_filename if output_filename
