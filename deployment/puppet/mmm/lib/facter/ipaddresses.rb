# ipaddresses.rb
#
# Adds a facter variable named 'ipaddresses' that
# parses the output of ifconfig to find the
# ip addresses

interface_ips = `ifconfig | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1 | awk '{printf $0";"}'`

Facter.add("ipaddresses") do
  setcode do
    interface_ips
  end
end
