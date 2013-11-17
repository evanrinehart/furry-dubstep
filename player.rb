class Player

  class Error < StandardError; end

  def initialize id, tell, kick, mud
    @id = id
    @tell = tell
    @kick = kick
    @handler = :login
    @account = nil
    @mud = mud
  end

  attr_reader :id
  attr_reader :account

  def tell msg
    @tell[msg]
  end

  def puts msg
    @tell[msg]
    @tell["\n"]
  end

  def kick
    @kick[]
  end

  def resume msg
    prompt, cont = @mud.send(@handler, self, msg)
    tell prompt
    @handler = cont
  end

  def bootstrap
    resume ''
  end

  def account= account
    raise Error, "don't try to set a players account twice" if @account
    @account = account
  end

  def prompt
    "> "
  end

end



