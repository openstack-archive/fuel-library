# L23network OS-aware constants
#
class l23network::params {
  $need_datapath_module = !str2bool($::kern_has_ovs_datapath)

  $lnx_bridge_tools = 'bridge-utils'

  case $::osfamily {
    /(?i)debian/: {
      $interfaces_dir     = '/etc/network/interfaces.d'
      $interfaces_file    = '/etc/network/interfaces'
      $ovs_service_name   = 'openvswitch-switch'
      $ovs_status_cmd     = '/etc/init.d/openvswitch-switch status'
      $lnx_vlan_tools     = 'vlan'
      $lnx_bond_tools     = 'ifenslave'
      $lnx_ethernet_tools = 'ethtool'
      $ovs_datapath_package_name = $need_datapath_module ? {
        true    => 'openvswitch-datapath-lts-saucy-dkms',
        default => false
      }
      $ovs_common_package_name = 'openvswitch-switch'
    }
    /(?i)redhat/: {
      $interfaces_dir     = '/etc/sysconfig/network-scripts'
      $interfaces_file    = undef
      $ovs_service_name   = 'openvswitch'
      $ovs_status_cmd     = '/etc/init.d/openvswitch status'
      $lnx_vlan_tools     = 'vconfig'
      $lnx_bond_tools     = undef
      $lnx_ethernet_tools = 'ethtool'
      $ovs_datapath_package_name = 'kmod-openvswitch'
      $ovs_common_package_name   = 'openvswitch'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
