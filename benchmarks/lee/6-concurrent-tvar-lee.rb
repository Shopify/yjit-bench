# Solves a board using TVar actually on two uncontrolled concurrent threads.

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

# Would be good if we could have TArray and TMatrix instead of a Matrix of TVars!

depth = Lee::Matrix.new(board.height, board.width) { Thread::TVar.new(0) }

def expand(board, obstructed, depth, route)
  start_point = route.a
  end_point = route.b

  # From benchmarking - we're better of allocating a new cost-matrix each time rather than zeroing
  cost = Lee::Matrix.new(board.height, board.width)
  cost[start_point.y, start_point.x] = 1

  wavefront = [start_point]

  loop do
    new_wavefront = []

    wavefront.each do |point|
      point_cost = cost[point.y, point.x]
      Lee.adjacent(board, point).each do |adjacent|
        next if obstructed[adjacent.y, adjacent.x] == 1 && adjacent != route.b
        current_cost = cost[adjacent.y, adjacent.x]
        new_cost = point_cost + Lee.cost(depth[adjacent.y, adjacent.x].value)
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

  cost
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
    depth[point.y, point.x].increment
  end
end

worklist = Queue.new
board.routes.each do |route|
  worklist.push route
end

solutions = {}

$committed = 0
$aborted = 0

class Thread
  LOG_LOCK = Mutex.new

  def self.committed
    LOG_LOCK.synchronize do
      $committed += 1
    end
  end

  def self.aborted
    LOG_LOCK.synchronize do
      $aborted += 1
    end
  end
end

threads = 2.times.map {
  Thread.new {
    loop do
      route = worklist.pop(non_block: true) rescue break

      Thread.atomically do
        cost = expand(board, obstructed, depth, route)
        solution = solve(board, route, cost)

        if expansions_dir
        Lee.draw board, solutions.values, [[cost.keys, solution]], File.join(expansions_dir, "expansion-#{route.object_id}.svg")
        end

        lay depth, solution
        solutions[route] = solution
      end
    end
  }
}

threads.each &:join

raise 'invalid solution' unless Lee.solution_valid?(board, solutions)

cost, depth = Lee.cost_solutions(board, solutions)
puts "routes:      #{board.routes.size}"
puts "committed:   #{$committed}"
puts "aborted:     #{$aborted}"
puts "cost:        #{cost}"
puts "depth:       #{depth}"

Lee.draw board, solutions.values, output_filename if output_filename
