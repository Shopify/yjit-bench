def group_from(x, y)
  group_tracker.group_of(board.identifier_for(x, y))
end

def board_at(x, y)
  from_board_at(board, x, y)
end

def from_board_at(board, x, y)
  board[board.identifier_for(x, y)]
end

def force_next_move_to_be(color, game)
  return if game.next_turn_color == color
  game.set_valid_move nil, Rubykon::Game.other_color(color)
end

def should_be_invalid_move(move, game)
  move_validate_should_return(false, move, game)
end

def should_be_valid_move(move, game)
  move_validate_should_return(true, move, game)
end

def move_validate_should_return(bool, move, game)
  identifier = game.board.identifier_for(move[0], move[1])
  color = move[2]
  expect(validator.valid?(identifier, color, game)).to be bool
end