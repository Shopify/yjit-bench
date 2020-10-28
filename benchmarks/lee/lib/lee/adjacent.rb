module Lee

  # Is a point within the bounds of a board?
  def self.point_on_board?(board, point)
    point.x >= 0 && point.y >= 0 && point.x < board.width && point.y < board.height
  end

  # Is a route within the bounds of a board? Not the solution - just the start and end of the route.
  def self.route_on_board?(board, route)
    point_on_board?(board, route.a) && point_on_board?(board, route.b)
  end
  
  # Get all points rectilinearly adjacent to another point, even if they're not on the board.
  def self.unsafe_adjacent(point)
    [
      Point.new(point.x - 1, point.y),
      Point.new(point.x, point.y - 1),
      Point.new(point.x + 1, point.y),
      Point.new(point.x, point.y + 1)
    ]
  end

  # Get all points rectilinearly adjacent to another point, but only those on the board.
  def self.adjacent(board, point)
    unsafe_adjacent(point).select { |adjacent| point_on_board?(board, adjacent) }
  end

end
