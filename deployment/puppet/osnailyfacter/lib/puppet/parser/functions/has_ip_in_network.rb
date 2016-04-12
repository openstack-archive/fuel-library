require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:has_ip_in_network, :type => :rvalue, :arity => 2, :doc => <<-EOS
This function checks if IP addresses (1st arg) is a part of given IP network (2nd arg).
EOS
  ) do |args|
    begin
      return IPAddr.new(args[1]).include?(args[0])
    rescue ArgumentError => e
      raise Puppet::ParseError, "Can't check if #{args[1]} includes #{args[0]}: #{e}"
    end
  end
end

