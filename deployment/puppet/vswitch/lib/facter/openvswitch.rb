# Fact: openvswitch ports
#
# Purpose: On any OS - return info about ovs ports for all bridges
#
# Resolution:
#
# Caveats:

begin
  require 'facter/kernel_modules.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__), 'kernel_modules.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

def ovs_vsctl
  "/usr/bin/ovs-vsctl"
end

def ovs_ofctl
  "/usr/bin/ovs-ofctl"
end

def openvswitch_module
  (Facter.value('osfamily') != 'Debian') ? 'openvswitch' : 'openvswitch_mod'
end


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
        return exec(ovs_vsctl, cmd)
    end

    def self.list_br
        return vsctl("list-br")
    end

    def self.list_ports(bridge)
        return vsctl("list-ports " + bridge)
    end

    # OpenFlow
    def self.ofctl(cmd)
        return exec(ovs_ofctl, cmd)
    end

    def self.of_show(bridge="")
        return ofctl("show " + bridge)
    end
end


Facter.add("openvswitch_module") do
    setcode do
        modules = Facter.value(:kernel_modules)
        if modules
            modules.split(",").include? openvswitch_module
        else
            false
        end
    end
end


if Facter.value(:openvswitch_module) == true && File.exists?(ovs_vsctl)
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
