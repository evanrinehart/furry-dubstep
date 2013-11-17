class Mud

  def login player, msg=''
    ["enter a secret passphrase: ", :enter_passphrase]
  end

  def enter_passphrase player, msg
    account = @db.auth_account msg
    if account.nil?
      player.session = msg
      ["do you want to create a new account with this secret? ", :confirm_create]
    else
      login_success player, account
    end
  end

  def confirm_create player, msg
    if msg =~ /y(es|eah|ep)?/
      account = @db.create_account player.session
      player.session = nil
      login_success player, account
    else
      login player
    end
  end

  def login_success player, account
    player.account = account
    player.puts "you are now logged in"
    player.puts "OMG SPLASH SCREEN"
    [player.prompt, :prompt]
  end

  def prompt player, msg
    if !msg.empty?
      command, *args = parse_command msg
      self.send('cmd_'+command.to_s, player, *args)
    end

    [player.prompt, :prompt]
  end

end
