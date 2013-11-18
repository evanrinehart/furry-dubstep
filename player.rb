class Player

  class Error < StandardError; end

  def initialize id, tell, kick, mud, db
    @id = id
    @tell = tell
    @kick = kick
    @handler = :login
    @account_id = nil
    @mud = mud
    @db = db
  end

  attr_reader :id
  attr_reader :session
  attr_reader :account_id
  attr_writer :session

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

  def account_id= account_id
    raise Error, "don't try to set a players account twice" if @account_id
    @account_id = account_id
  end

  def account
    @db.account(@account_id)
  end

  def unit
    a = account
    a && @db.unit(a[:unit_id])
  end

  def unit_id
    u = unit
    u && u[:id]
  end

  def name
    @account_id.nil? ? "UNAUTH" : @db.account(@account_id)[:name]
  end

  def prompt
    "#{name}> "
  end

  def location
    u = unit
    u && u[:location]
  end

end



