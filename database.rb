require './acid'
require './secret'

class Database

  class Error < StandardError; end

  def initialize

    @acid = Acid.new 'world.db' do

      init do
        {
          :counter => 0,
          :accounts => {}
        }
      end

      update :create_account do |s, hash|
        id = s[:counter]
        s[:counter] += 1
        s[:accounts][id] = {
          :id => id,
          :secret => hash,
          :name => "CMNDR",
        }
        [s, id]
      end

      view :state do |s| s end
      view :account do |s, id| s[:accounts][id] end

    end

    state = @acid.state
    @account_by_secret = unique_index(state[:accounts], :secret)
    
  end

  def create_account secret
    fp = Secret.hash secret
    raise Error, "duplicate secret" if @account_by_secret.has_key?(fp)
    id = @acid.create_account fp
    @account_by_secret[fp] = @acid.account(id)
    @acid.account(id)
  end

  def auth_account secret
    fp = Secret.hash secret
    @account_by_secret[fp]
  end

  def unique_index set, field
    table = {}
    set.each do |id, item|
      key = item[field]
      raise Error, "duplicate #{field} when building unique index" if table[key]
      table[key] = item
    end
    table
  end

end
