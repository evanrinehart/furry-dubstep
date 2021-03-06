require './acid'
require './secret'

class Database

  class Error < StandardError; end

  def initialize

    db = self
    @acid = Acid.new 'world.db' do

      init do
        {
          :counter => 0,
          :accounts => {},
          :units => {},
          :land_links => {}
        }
      end

      serialize do |s|
        {
          :counter => s[:counter],
          :accounts => s[:accounts].values,
          :units => s[:units].values,
          :land_links => s[:land_links].map{|a,s| s.keys.map{|b| [a,b]}}.flatten(1)
        }
      end

      deserialize do |p|
        {
          :counter => p[:counter],
          :accounts => db.list_to_index(p[:accounts], :id),
          :units => db.list_to_index(p[:units], :id),
          :land_links => db.pairs_to_index(p[:land_links])
        }
      end

      update_mr :create_account do |s, hash|
        id = s[:counter]
        s[:counter] += 1
        s[:accounts][id] = {
          :id => id,
          :secret => hash,
          :name => "CMNDR",
          :unit_id => nil
        }
        id
      end

      update_m :set_account_name do |s, id, name|
        s[:accounts][id][:name] = name
      end

      update_mr :create_unit do |s, uc, location|
        id = s[:counter]
        s[:counter] += 1
        s[:units][id] = {
          :id => id,
          :class => uc,
          :location => location
        }
        id
      end

      update_m :delete_unit do |s, uid|
        s[:units].delete uid
      end

      update_m :set_account_unit do |s, aid, uid|
        s[:accounts][aid][:unit_id] = uid
      end

      update_m :create_land_link do |s, land0, land1|
        if s[:land_links][land0].nil?
          s[:land_links][land0] = {}
        end
        s[:land_links][land0][land1] = nil
      end

      update_m :delete_land_link do |s, land0, land1|
        if s[:land_links][land0]
          s[:land_links][land0].delete(land1)
        end
      end

      update_m :move_unit do |s, uid, loc|
        s[:units][uid][:location] = loc
      end

      view :state do |s| s end
      view :account do |s, id| s[:accounts][id] end
      view :unit do |s, id| s[:units][id] end
      view :links_from_land do |s, land| (s[:land_links][land]||{}).keys end

    end

    state = @acid.state
    @account_by_secret = unique_index(state[:accounts], :secret)
    @account_by_unit_id = unique_index(state[:accounts], :unit_id)
    @unit_ids_by_location = index(state[:units], :location)

  end

  def units_in_location loc
    (@unit_ids_by_location[loc]||{}).keys.map do |uid|
      @acid.unit(uid)
    end
  end

  def create_account secret
    fp = Secret.hash secret
    raise Error, "duplicate secret" if @account_by_secret.has_key?(fp)
    id = @acid.create_account fp
    @account_by_secret[fp] = @acid.account(id)
    @acid.account(id)
  end

  def set_account_name id, name
    @acid.set_account_name id, name
  end

  def set_account_unit aid, uid
    raise Error, "no account #{aid}" if @acid.account(aid).nil?
    @acid.set_account_unit aid, uid
    @account_by_unit_id[uid] = @acid.account(aid)
  end

  def auth_account secret
    fp = Secret.hash secret
    @account_by_secret[fp]
  end

  def account id
    @acid.account(id)
  end

  def unit id
    @acid.unit(id)
  end

  def create_unit unit_class, location
    uid = @acid.create_unit unit_class, location
    write_index @unit_ids_by_location, location, uid
    uid
  end

  def delete_unit uid
    account = @account_by_unit_id[uid]
    if account
      puts "WARNING aborting attempt to delete an accounts main unit"
      return
    end

    unit = @acid.unit(uid)
    loc = unit[:location]
    (@unit_ids_by_location[loc]||{}).delete(uid)
    @acid.delete_unit uid
  end

  def create_link land0, land1
    @acid.create_land_link land0, land1
  end

  def delete_link land0, land1
    @acid.delete_land_link land0, land1
  end

  def account_for_unit uid
    @account_by_unit_id[uid]
  end

  def move_unit uid, location
    raise Error, "invalid location" if !LANDS.include?(location)
    loc0 = @acid.unit(uid)[:location]
    @acid.move_unit uid, location
    clear_index @unit_ids_by_location, loc0, uid
    write_index @unit_ids_by_location, location, uid
  end

  def checkpoint
    @acid.checkpoint
  end

  def links_from_land land
    @acid.links_from_land land
  end

  def unique_index set, field
    table = {}
    set.each do |id, item|
      key = item[field]
      next if key.nil?
      raise Error, "duplicate #{field} when building unique index (#{key} -> #{id})" if table[key]
      table[key] = item
    end
    table
  end

  def index set, field
    table = {}
    set.each do |id, item|
      key = item[field]
      next if key.nil?
      write_index table, key, id
    end
    table
  end

  def write_index index, key, element
    if !index.has_key?(key)
      index[key] = {}
    end
    index[key][element] = nil
  end

  def clear_index index, key, element
    if index.has_key?(key)
      index[key].delete(element)
    end
  end

  def list_to_index list, field
    s = {}
    list.each{|x| s[x[field]] = x}
    s
  end

  def list_to_set list
    s = {}
    list.each{|x| s[x] = nil}
    s
  end

  def pairs_to_index pairs
    s = {}
    pairs.each do |a,b|
      if !s.has_key? a
        s[a] = {}
      end
      s[a][b] = nil
    end
    s
  end

end
