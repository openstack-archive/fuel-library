# Fact: openvswitch ports
#
# Purpose: On any OS - return info about ovs ports for all bridges
#
# Resolution:
#
# Caveats:
require "facter"
require "facter/kernel_modules"
require "set"

VSCTL = "/usr/bin/ovs-vsctl"
OFCTL = "/usr/bin/ovs-ofctl"

module OpenVSwitch
    def self.exec(bin, cmd)
        result = Facter::Util::Resolution.exec(bin + " " + cmd)
        if result
            result = result.split("\n")
        end
        return result
    end

    # vSwitch
    def self.vsctl(cmd)
        return exec(VSCTL, cmd)
    end

    def self.list_br
        return vsctl("list-br")
    end

    def self.list_ports(bridge)
        return vsctl("list-ports " + bridge)
    end

    # OpenFlow
    def self.ofctl(cmd)
        return exec(OFCTL, cmd)
    end

    def self.of_show(bridge="")
        return ofctl("show " + bridge)
    end
end


Facter.add("openvswitch_module") do
    setcode do
        Facter.value(:kernel_modules).split(",").include? "openvswitch"
    end
end


if Facter.value(:openvswitch_module) == true && File.exists?(VSCTL)
    bridges = OpenVSwitch.list_br || []

    Facter.add("openvswitch_bridges") do
        setcode do
            bridges.join(",")
        end
    end

    bridges.each do |bridge|
        ports = OpenVSwitch.list_ports(bridge)
        if ports
            Facter.add("openvswitch_ports_#{bridge}") do
                setcode do
                    ports.join(",")
                end
            end
        end
    end
end
