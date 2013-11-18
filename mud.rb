require './demogorgon'
require './player'
require './database'
require './dialog'
require './lookup'
require './parser'
require './commands'
require './intercom'
require './land'

class Mud

  class Bug < StandardError; end

  def initialize at
    @at = at
    @db = Database.new
    @players = {}
  end

  def at time, &block
    @at.call(time, &block)
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

  def wakeup
    global_msg "BING BONG"
  end

end
