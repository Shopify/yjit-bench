# Solves a board, two routes at a time, applying the two routes in transactions
# which are checked against each other for conflicts, drawing intermediate
# results.

require 'set'

require_relative 'lib/lee'

board_filename, output_filename, expansions_dir, *rest = ARGV
raise 'no input filename' unless board_filename
raise 'too many arguments' unless rest.empty?

if expansions_dir
  system 'rm', '-rf', expansions_dir
  Dir.mkdir expansions_dir
end

board = Lee.read_board(board_filename)

obstructed = Lee::Matrix.new(board.height, board.width)
board.pads.each do |pad|
  obstructed[pad.y, pad.x] = 1
end

depth = Lee::Matrix.new(board.height, board.width)

def expand(board, obstructed, depth, route)
  start_point = route.a
  end_point = route.b

  # From benchmarking - we're better of allocating a new cost-matrix each time rather than zeroing
  cost = Lee::Matrix.new(board.height, board.width)
  cost[start_point.y, start_point.x] = 1

  read_set = Set.new

  wavefront = [start_point]

  loop do
    new_wavefront = []

    wavefront.each do |point|
      point_cost = cost[point.y, point.x]
      Lee.adjacent(board, point).each do |adjacent|
        next if obstructed[adjacent.y, adjacent.x] == 1 && adjacent != route.b
        current_cost = cost[adjacent.y, adjacent.x]
        read_set.add adjacent
        new_cost = point_cost + Lee.cost(depth[adjacent.y, adjacent.x])
        if current_cost == 0 || new_cost < current_cost
          cost[adjacent.y, adjacent.x] = new_cost
          new_wavefront.push adjacent
        end
      end
    end

    raise 'stuck' if new_wavefront.empty?
    break if cost[end_point.y, end_point.x] > 0 && cost[end_point.y, end_point.x] < new_wavefront.map { |marked| cost[marked.y, marked.x] }.min

    wavefront = new_wavefront
  end

  [read_set, cost]
end

def solve(board, route, cost)
  start_point = route.b
  end_point = route.a

  solution = [start_point]

  loop do
    adjacent = Lee.adjacent(board, solution.last)
    lowest_cost = adjacent
      .reject { |a| cost[a.y, a.x].zero? }
      .min_by { |a| cost[a.y, a.x] }
    solution.push lowest_cost
    break if lowest_cost == end_point
  end

  solution.reverse
end

def lay(depth, solution)
  solution.each do |point|
    depth[point.y, point.x] += 1
  end
end

solutions = {}

worklist = board.routes.dup

independent = 0
overlaps = 0
conflicts = 0
spare = 0

counter = 10000

until worklist.empty?
  a = worklist.shift
  b = worklist.shift

  if b
    a_read, cost_a = expand(board, obstructed, depth, a)
    b_read, cost_b = expand(board, obstructed, depth, b)

    solution_a = solve(board, a, cost_a)
    solution_b = solve(board, b, cost_b)

    a_write = Set.new(solution_a)
    b_write = Set.new(solution_b)

    expansions_job = [[a_read, solution_a], [b_read, solution_b]]

    if a_read.intersect?(b_write) || b_read.intersect?(a_write)
      result = 'conflict'
      conflicts += 1

      (abort, abort_solution), (commit, commit_solution) = [[a, solution_a], [b, solution_b]].sort_by { |route, solution| solution.size }

      lay depth, commit_solution
      solutions[commit] = commit_solution

      worklist.unshift abort
    else
      lay depth, solution_a
      solutions[a] = solution_a

      lay depth, solution_b
      solutions[b] = solution_b

      if a_read.intersect?(b_read)
        result = 'overlaps'
        overlaps += 1
      else
        result = 'independent'
        independent += 1
      end
    end

    if expansions_dir
      Lee.draw board, solutions.values, expansions_job, File.join(expansions_dir, "#{counter}-#{result}-#{a.object_id}-#{b.object_id}.svg")
    end
  else
    read_set, cost = expand(board, obstructed, depth, a)
    solution = solve(board, a, cost)
    lay depth, solution
    solutions[a] = solution
    spare += 1
    
    if expansions_dir
      Lee.draw board, [solution], [[read_set, solution]], File.join(expansions_dir, "#{counter}-spare-#{a.object_id}.svg")
    end
  end

  counter += 1
end

raise 'invalid solution' unless Lee.solution_valid?(board, solutions)

cost, depth = Lee.cost_solutions(board, solutions)
puts "routes:      #{board.routes.size}"
puts "independent: #{independent}"
puts "overlaps:    #{overlaps}"
puts "conflicts:   #{conflicts}"
puts "spare:       #{spare}"
puts "cost:        #{cost}"
puts "depth:       #{depth}"

if expansions_dir
  100.times do
    Lee.draw board, solutions.values, File.join(expansions_dir, "#{counter}-final.svg")
    counter += 1
  end
end

Lee.draw board, solutions.values, output_filename if output_filename
