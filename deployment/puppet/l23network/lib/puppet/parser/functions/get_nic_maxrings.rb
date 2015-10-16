#
#  get_nic_maxrings.rb
#
require 'puppetx/l23_utils'

module Puppet::Parser::Functions
  newfunction(:get_nic_maxrings, :type => :rvalue, :doc => <<-EOS
Gets pre-set maximums of nic ring rx/tx settings by ethtool.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "get_nic_maxrings(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    iface_name = arguments[0]
    rings = L23network.get_ethtool_rings(iface_name)
    return { 'rings' => rings } unless rings.empty?
    rings
  end
end
# vim: set ts=2 sw=2 et :
