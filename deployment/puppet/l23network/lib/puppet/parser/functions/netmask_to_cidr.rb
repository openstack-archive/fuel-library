require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:netmask_to_cidr, :type => :rvalue, :doc => <<-EOS
This function get classic netmask and returns cidr masklen.
EOS
  ) do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "netmask_to_cidr(): Wrong number of arguments " +
        "given (#{arguments.size} for 1)")
    end

    return IPAddr.new(arguments[0]).to_i.to_s(2).count("1").to_s
  end
end
