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
    if LANDS.include? destination
      uid = player.unit_id
      @db.move_unit uid, destination
      cmd_look player
    else
      player.puts "don't try to go there"
    end
  end

  def cmd_look player
    loc = player.location
    units = @db.units_in_location loc
    player.puts loc
    player.puts "you see here:" if units.count > 0
    units.each do |u|
      account = @db.account_for_unit u[:id]
      if account
        player.puts " #{u[:class]} (#{account[:name]})"
      else
        player.puts " #{u[:class]}"
      end
    end
  end

  def cmd_examine player, text
    loc = player.location
    units = @db.units_in_location loc
    target = units.find{|x| x[:class] == text}
    if target.nil?
      player.puts "I see no #{text}"
    else
      player.puts "some #{target[:class]} unit"
    end
  end

  def cmd_checkpoint player
    @db.checkpoint
    player.puts "done"
  end


end
