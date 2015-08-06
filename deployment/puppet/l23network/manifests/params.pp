# L23network OS-aware constants
#
class l23network::params {
  $monolith_bond_providers = ['ovs']

  case $::osfamily {
    /(?i)debian/: {
      $interfaces_dir            = '/etc/network/interfaces.d'
      $interfaces_file           = '/etc/network/interfaces'
      $ovs_service_name          = 'openvswitch-switch'
      $ovs_status_cmd            = '/etc/init.d/openvswitch-switch status'
      $lnx_vlan_tools            = 'vlan'
      $lnx_bond_tools            = 'ifenslave'
      $lnx_ethernet_tools        = 'ethtool'
      $lnx_bridge_tools          = 'bridge-utils'
      $ovs_datapath_package_name = undef
      $ovs_common_package_name   = 'openvswitch-switch'
      $ovs_kern_module_name      = 'openvswitch'
      $extra_tools               = 'iputils-arping'
    }
    /(?i)redhat/: {
      $interfaces_dir            = '/etc/sysconfig/network-scripts'
      $interfaces_file           = undef
      $ovs_service_name          = 'openvswitch'
      $ovs_status_cmd            = '/etc/init.d/openvswitch status'
      $lnx_vlan_tools            = 'vconfig'
      $lnx_bond_tools            = undef
      $lnx_ethernet_tools        = 'ethtool'
      $lnx_bridge_tools          = 'bridge-utils'
      $ovs_datapath_package_name = 'kmod-openvswitch'
      $ovs_common_package_name   = 'openvswitch'
      $ovs_kern_module_name      = 'openvswitch'
      $extra_tools               = 'iputils'
    }
    /(?i)darwin/: {
      $interfaces_dir            = '/tmp/1'
      $interfaces_file           = undef
      $ovs_service_name          = undef
      $lnx_vlan_tools            = undef
      $lnx_bond_tools            = undef
      $lnx_ethernet_tools        = undef
      $lnx_bridge_tools          = undef
      $ovs_datapath_package_name = undef
      $ovs_common_package_name   = undef
      $ovs_kern_module_name      = unedf
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
