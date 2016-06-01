require 'ipaddr'
require_relative 'util/netstat'

# Fact: defaultroute
#
# Purpose: Return the default route for a host.
#
Facter.add(:l3_default_route) do
  confine :kernel => Facter::Util::NetStat.supported_platforms
  setcode do
    Facter::Util::NetStat.get_route_value('default', 'gw') ||
    Facter::Util::NetStat.get_route_value('0.0.0.0', 'gw')
  end
end

# Fact: l3_default_route_interface
#
# Purpose: Return the interface uses for the host's default route.
#
Facter.add(:l3_default_route_interface) do
  confine :kernel => Facter::Util::IP.supported_platforms
  setcode do
    defaultroute = Facter.value(:l3_default_route)
    if defaultroute
      gw = IPAddr.new(defaultroute)
      Facter::Util::IP.get_interfaces.detect do |i| 
        pi = Facter::Util::IP.alphafy(i)
        network = Facter.value('network_' + pi)
        netmask = Facter.value('netmask_' + pi)
        if network and netmask
            IPAddr.new(network+'/'+netmask).include?(gw)
        else
            false
        end
      end
    end
  end
end
