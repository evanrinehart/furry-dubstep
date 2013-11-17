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
    puts "#{id} connecting"
    @players[id] = Player.new id, tell, kick, lambda{|x,y| login x,y}
  end

  def disconnect id
    @players.delete(id)
    puts "#{id} disconnected"
  end

  def message id, msg
    player = get_player id
    player.resume(msg)
  end

  def login player, msg
puts msg.inspect
    puts "#{player.id} said: #{msg}"
    account = @db.auth_account msg
    if account.nil?
      account = @db.create_account msg
    end
puts account.inspect
    puts "you are logged in as #{account[:name]}"
    player.account = account
  end

end
