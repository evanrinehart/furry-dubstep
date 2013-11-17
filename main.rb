require './mud'
require './demogorgon'

Demogorgon.new do |at|

  mud = Mud.new at

  dialog 12345, {
    :connect => lambda{|id, tell, kick| mud.connect id, tell, kick},
    :message => lambda{|id, msg| mud.message id, msg},
    :disconnect => lambda{|id| mud.disconnect id}
  }

  on_schedule '0 * * * * *' do
    mud.wakeup
  end

end
