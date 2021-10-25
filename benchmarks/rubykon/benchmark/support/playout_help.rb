def full_playout_for(size)
  playout_object_for(size).play
end

def playout_for(size)
  playout_object = playout_object_for(size)
  playout_object.playout
  playout_object
end

def playout_object_for(size)
  MCTS::Playout.new(Rubykon::GameState.new Rubykon::Game.new(size))
end
