class Mud

  def cmd_unknown player
    player.puts "unknown command"
  end

  def cmd_quit player
    player.puts "you are about to be disconnected"
    player.kick
  end

  def cmd_name player, name
    if name.nil? || name.empty?
      player.puts "to change name use `name <desired name>'"
    elsif name !~ /^[A-Z]+$/ || name.length > 7
      player.puts "name must be A-Z and no longer than 7 letters"
    else
      @db.set_account_name player.account[:id], name
      player.puts "your name is now #{name}"
    end
  end

  def cmd_help player, topic
    player.puts "there is nothing I can do for you now"
  end

  def cmd_goto player, destination
    player.puts "hmmm"
  end

  def cmd_at player, wait
    t = Time.now + wait.to_i
    at t do
      player.puts "BONGGGGG"
    end
  end

end
