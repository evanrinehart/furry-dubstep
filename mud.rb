require './demogorgon'
require './player'
require './database'
require './dialog'
require './lookup'
require './parser'
require './commands'

class Mud

  class Bug < StandardError; end

  def initialize
    @db = Database.new
    @players = {}
  end

  def connect id, tell, kick
    player = Player.new id, tell, kick, self, @db
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

end
