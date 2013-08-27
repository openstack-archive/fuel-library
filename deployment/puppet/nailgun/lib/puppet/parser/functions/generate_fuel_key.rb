module Puppet::Parser::Functions
  newfunction(:generate_fuel_key, :type => :rvalue, :doc => <<-EOS
Returns unique Fuel key (UUID)
    EOS
  ) do |arguments|

    require 'uuidtools'

    return UUIDTools::UUID.random_create.to_str()
    
  end
end
