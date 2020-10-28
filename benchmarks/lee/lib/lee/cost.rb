module Lee

  # What is the cost of adding a new route on top of existing routes of a given depth?
  def self.cost(depth)
    # The cost is exponential - getting taller gets more expensive more quickly as the depth increases.
    2**depth
  end

  # How much does a set of solutions cost overall? And what's the max depth?
  def self.cost_solutions(board, solutions)
    depth = {}
    depth.default = 0

    cost = 0

    solutions.values.each do |solution|
      solution.each do |point|
        point_depth = depth[point]
        cost += cost(point_depth)
        depth[point] = point_depth + 1
      end
    end

    [cost, depth.values.max]
  end

end
