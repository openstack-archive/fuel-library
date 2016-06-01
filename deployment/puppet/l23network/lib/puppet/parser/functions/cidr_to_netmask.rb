require 'ipaddr'
require_relative 'lib/prepare_cidr'

module Puppet::Parser::Functions
  newfunction(:cidr_to_netmask, :type => :rvalue, :doc => <<-EOS
This function get cidr-notated IP addresses and return netmask.
EOS
  ) do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "cidr_to_netmask(): Wrong number of arguments " +
        "given (#{arguments.size} for 1)")
    end

    masklen = prepare_cidr(arguments[0])[1]
    return IPAddr.new('255.255.255.255').mask(masklen).to_s
  end
end
