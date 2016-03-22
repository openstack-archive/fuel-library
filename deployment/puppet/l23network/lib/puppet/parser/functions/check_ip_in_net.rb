require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:check_ip_in_net, :type => :rvalue, :doc => <<-EOS
This function checks if IP addresses (1st arg) is a part of given IP network (2nd arg).
EOS
  ) do |arguments|
    if arguments.size != 2
      raise(Puppet::ParseError, "check_ip_in_net(): Wrong number of arguments: " +
        "given (#{arguments.size}, but expected 2)")
    end

    return IPAddr.new(arguments[1]).include?(arguments[0])
  end
end

