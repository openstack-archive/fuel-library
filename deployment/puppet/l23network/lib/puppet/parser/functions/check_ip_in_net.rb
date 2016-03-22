require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:check_ip_in_net, :type => :rvalue, :arity => 2, :doc => <<-EOS
This function checks if IP addresses (1st arg) is a part of given IP network (2nd arg).
EOS
  ) do |arguments|
    return IPAddr.new(arguments[1]).include?(arguments[0])
  end
end

