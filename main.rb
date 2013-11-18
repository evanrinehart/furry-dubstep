require './mud'
require './demogorgon'

Demogorgon.new do |at|

  mud = Mud.new at

  dialog 12345, {
    :connect => mud.method(:connect),
    :message => mud.method(:message),
    :disconnect => mud.method(:disconnect)
  }

end
