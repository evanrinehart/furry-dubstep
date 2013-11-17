class Mud

  def get_player id
    @players[id] || raise(Bug, "player #{id} not found")
  end

end
