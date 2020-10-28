module Lee

  # Is a board valid? With all pads and routes within the bounds of the board.
  def self.board_valid?(board)
    board.pads.all? { |pad| point_on_board?(board, pad) } &&
      board.routes.all? { |route| route_on_board?(board, route) }
  end

  # Are the board and all solutions valid? With solutions continuous and matching the route.
  def self.solution_valid?(board, solutions)
    return false unless board_valid?(board)
    board.routes.all? { |route|
      solution = solutions[route]
      return false unless solution
      return false unless solution.first == route.a
      return false unless solution.last == route.b
      previous = solution.first
      solution.drop(1).each do |point|
        return false unless point_on_board?(board, point)
        return false unless adjacent(board, previous).include?(point)
        return false unless adjacent(board, point).include?(previous)
        previous = point
      end
    }
  end

end
