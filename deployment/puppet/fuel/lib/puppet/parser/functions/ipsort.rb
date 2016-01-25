module Puppet::Parser::Functions
  newfunction(:ipsort, :type => :rvalue , :doc => <<-EOS
Returns list sorted of sorted IP addresses.
  EOS
) do |args|
    require 'rubygems'
    require 'ipaddr'
    ips = args[0]
    sorted_ips = ips.sort { |a,b| IPAddr.new( a ) <=> IPAddr.new( b ) } 
    sorted_ips
  end
end

