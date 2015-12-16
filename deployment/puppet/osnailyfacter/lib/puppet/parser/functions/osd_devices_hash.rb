module Puppet::Parser::Functions
  newfunction(:osd_devices_hash, :type => :rvalue,
:doc => <<-EOS
Returns the hash of osd devices for create_resources puppet function
EOS
  ) do |arguments|

    raise(Puppet::ParseError, "Wrong number of arguments (#{arguments.length} for 1).") if arguments.size != 1
    raise(Puppet::ParseError, "Argument should be a String.") if !arguments[0].is_a?(String)

    devices_array = arguments[0].split(" ").map{|value| value.split(":")}
    devices_hash = devices_array.inject({}) do |memo, (key, value)|
      memo[key] = {'journal' => value}
      memo
    end
    return devices_hash
  end
end

