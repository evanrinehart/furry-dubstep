class Mud

  def global_msg msg
    @players.each do |id, player|
      if player.account
        player.puts msg
      end
    end
  end

end
