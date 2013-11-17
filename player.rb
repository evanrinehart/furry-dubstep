class Player

  class Error < StandardError; end

  def initialize id, tell, kick, login
    @id = id
    @tell = tell
    @kick = kick
    @continuation = login
    @account = nil
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

  def read &block
    @continuation = block
  end

  def resume msg
    @continuation[self, msg]
  end

  def account= account
    raise Error, "don't try to set a players account twice" if @account
    @account = account
  end

end



