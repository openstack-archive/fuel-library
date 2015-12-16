module Puppet::Parser::Functions
  newfunction(:osd_devices_hash, :type => :rvalue,
:doc => <<-EOS
Returns the hash of osd devices for create_resources puppet function
EOS
  ) do |arguments|
    devices_array = arguments[0].split(" ").map{|value| value.split(":")}
    devices_hash = devices_array.inject({}) do |memo, (key, value)|
      memo[key] = {'journal' => value}
      memo
    end
    return devices_hash
  end
end

