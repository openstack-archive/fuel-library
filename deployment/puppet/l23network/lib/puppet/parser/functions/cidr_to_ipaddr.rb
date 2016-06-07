require_relative 'lib/prepare_cidr'

module Puppet::Parser::Functions
  newfunction(:cidr_to_ipaddr, :type => :rvalue, :doc => <<-EOS
This function get cidr-notated IP addresses and return ip address.
EOS
  ) do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "cidr_to_ipaddr(): Wrong number of arguments " +
        "given (#{arguments.size} for 1)") 
    end

    return prepare_cidr(arguments[0])[0]
  end
end
