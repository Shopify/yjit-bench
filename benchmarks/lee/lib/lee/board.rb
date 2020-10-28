module Lee

  # A point is a location on the board.
  Point = Struct.new(:x, :y)

  # A route is two points that we want to connect. It's a route to solve, not a route that has been solved.
  Route = Struct.new(:a, :b)

  # A board has a width, height, an array of pads, and an array of routes to solve.
  Board = Struct.new(:width, :height, :pads, :routes)

  # Read a board from a file.
  def self.read_board(filename)
    width = nil
    height = nil
    pads = []
    routes = []

    File.open(filename) do |file|
      file.each_line do |line|
        tokens = line.split(' ')
        tokens[1..-1] = tokens[1..-1].map(&:to_i)
        case tokens[0]
        when 'B'
          _, width, height, *rest = tokens
          raise 'bad B line command' unless rest.empty? && ![width, height].any?(&:nil?)
        when 'P'
          _, x, y, *rest = tokens
          raise 'bad P line command' unless rest.empty? && ![x, y].any?(&:nil?)
          pads.push Point.new(x, y)
        when 'J'
          _, ax, ay, bx, by, *rest = tokens
          raise 'bad J line command' unless rest.empty? && ![ax, ay, bx, by].any?(&:nil?)
          routes.push Route.new(Point.new(ax, ay), Point.new(bx, by))
        when 'E'
          break
        else
          raise "unknown board line command #{tokens[0].inspect}"
        end
      end
    end

    raise 'board size not set' unless width && height

    # Deterministically shuffle the routes to reduce obvious conflicts
    routes.shuffle! random: Random.new(0)

    board = Board.new(width, height, pads, routes)
    raise 'invalid board' unless board_valid?(board)
    board
  end

end
