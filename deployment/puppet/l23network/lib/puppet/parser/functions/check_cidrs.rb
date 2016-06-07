require_relative 'lib/prepare_cidr'

module Puppet::Parser::Functions
  newfunction(:check_cidrs, :doc => <<-EOS
This function get array of cidr-notated IP addresses and check it syntax.
Raise exception if syntax not right. 
EOS
  ) do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "check_cidrs(): Wrong number of arguments " +
        "given (#{arguments.size} for 1)") 
    end

    cidrs = arguments[0]

    if ! cidrs.is_a?(Array)
      raise(Puppet::ParseError, 'check_cidrs(): Requires array of IP addresses.')
    end
    if cidrs.length < 1
      raise(Puppet::ParseError, 'check_cidrs(): Must given one or more IP address.')
    end

    for cidr in cidrs do
      prepare_cidr(cidr)
    end

    return true
  end
end

# vim: set ts=2 sw=2 et :
