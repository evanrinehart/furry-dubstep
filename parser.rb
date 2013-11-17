COMMANDS = [
  {
    :names => ['quit','exit'],
    :form => 'v'
  },
  {
    :names => ['name'],
    :form => 'vx'
  },
  {
    :names => ['help'],
    :form => 'vx'
  },
  {
    :names => ['goto', 'go'],
    :form => 'vx'
  }
]

class Mud

  def parse_command msg
    rest = nil
    word0 = nil
    cmd = COMMANDS.find do |cmd|
      word0, rest = msg.split(/\s+/, 2)
      cmd[:names].include? word0
    end

    return :unknown if cmd.nil?

    name = cmd[:names].first

    case cmd[:form]
      when 'v' then name
      when 'vx' then [name, rest]
      else raise Bug, "unknown command form #{cmd[:form]}"
    end
      
  end

end
