
def uname_r()
  vers_lines = File.readlines("/proc/sys/kernel/osrelease")
  return vers_lines[0].chomp
end

def kernel_has_ovs_datapath()
  has_ovs = false
  has_ovs_gre = false
  has_ovs_vxlan = false
  File.open("/boot/config-#{uname_r}", "r") do |kernel_conf|
    while (knob = kernel_conf.gets)
      case knob
        when /^CONFIG_OPENVSWITCH[=][ym]$/
          has_ovs = true
        when /^CONFIG_OPENVSWITCH_GRE[=][ym]$/
          has_ovs_gre = true
        when /^CONFIG_OPENVSWITCH_VXLAN[=][ym]$/
          has_ovs_vxlan = true
        end
    end
  end
  return has_ovs && has_ovs_gre && has_ovs_vxlan
end

Facter.add('kern_has_ovs_datapath') do
  setcode do
    kernel_has_ovs_datapath
  end
end

