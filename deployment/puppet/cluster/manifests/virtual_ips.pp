# == Define: cluster::virtual_ips
#
# Configure set of VirtualIP resources for corosync/pacemaker.
#
# === Parameters
#
# [*vips*]
#   Specify dictionary of VIPs describing. Ex:
#   {
#     virtual_ip1_name => {
#       nic    => 'eth0',	
#       ip     => '10.1.1.253'
#     },
#     virtual_ip2_name => {
#       nic    => 'eth2',
#       ip     => '192.168.12.254',
#     },
#   }
#
# [*name*]
#   keys($vips) list, need for emulating loop in puppet.
#
define cluster::virtual_ips (
  $vips
){
  cluster::virtual_ip {"$name":
    vip => $vips[$name],
  }
}
#
###