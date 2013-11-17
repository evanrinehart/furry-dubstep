class Mud

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

  def cmd_unknown player
    player.puts "unknown command"
  end

end