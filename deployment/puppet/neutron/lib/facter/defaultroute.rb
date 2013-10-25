require 'ipaddr'

begin
  require 'facter/util/netstat.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__), 'util', 'netstat.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

# Fact: defaultroute
#
# Purpose: Return the default route for a host.
#
# Resolution:
#   Runs netstat, and returns the gateway associated with the destination
#   "default" or "0.0.0.0".
#
# Caveats:
#

Facter.add(:defaultroute) do
  confine :kernel => Facter::Util::NetStat.supported_platforms
  setcode do
    Facter::Util::NetStat.get_route_value('default', 'gw') ||
    Facter::Util::NetStat.get_route_value('0.0.0.0', 'gw')
  end
end

# Fact: defaultroute_interface
#
# Purpose: Return the interface uses for the host's default route.
#
# Resolution:
#   Runs netstat, and returns the interface associated with the route for the
#   destination "default" or "0.0.0.0".
#
#   If the default route listing only includes the gateway and not the
#   interface (as is the case on Solaris), return the first interface whose
#   network range includes the default gateway.
#
# Caveats:
#

Facter.add(:defaultroute_interface) do
  confine :kernel => Facter::Util::IP.supported_platforms
  setcode do
    defaultroute = Facter.value(:defaultroute)
    if defaultroute
      gw = IPAddr.new(defaultroute)
      Facter::Util::IP.get_interfaces.collect { |i| Facter::Util::IP.alphafy(i) }.
      detect do |i| 
        network = Facter.value('network_' + i)
        netmask = Facter.value('netmask_' + i)
        if network and netmask
            IPAddr.new(network+'/'+netmask).include?(gw)
        else
            false
        end
      end
    end
  end
end
