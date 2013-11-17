require './demogorgon'
require './player'
require './database'

class Mud

  class Bug < StandardError; end

  def initialize
    @db = Database.new
    @players = {}
  end

  def get_player id
    @players[id] || raise(Bug, "player #{id} not found")
  end

  def connect id, tell, kick
    player = Player.new id, tell, kick, self
    raise Bug, "player #{id} is already connected?" if @players[id]
    @players[id] = player
    player.bootstrap
    puts "#{id} connected"
  end

  def disconnect id
    @players.delete(id)
    puts "#{id} disconnected"
  end

  def message id, msg
    player = get_player id
    player.resume(msg)
  end

  def login player, msg=''
    ["enter a secret passphrase: ", :enter_passphrase]
  end

  def enter_passphrase player, msg
    account = @db.auth_account msg
    if account.nil?
      ["do you want to create a new account with this secret? ", :confirm_create]
    else
      login_success player, account
    end
  end

  def confirm_create player, msg
    if msg =~ /y(es|eah|ep)?/
      account = @db.create_account msg
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
    player.puts "i heard"
    [player.prompt, :prompt]
  end

end
