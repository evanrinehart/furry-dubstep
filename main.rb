require './mud'
require './demogorgon'

Demogorgon.new do

  mud = Mud.new

  dialog 12345, {
    :connect => lambda{|id, tell, kick| mud.connect id, tell, kick},
    :message => lambda{|id, msg| mud.message id, msg},
    :disconnect => lambda{|id| mud.disconnect id}
  }

end
