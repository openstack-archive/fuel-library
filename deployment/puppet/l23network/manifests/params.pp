# L23network OS-aware constants
#
class l23network::params {
  $monolith_bond_providers = ['ovs']

  case $l23_os {
    /(?i)ubuntu/: {
      $interfaces_dir            = '/etc/network/interfaces.d'
      $interfaces_file           = '/etc/network/interfaces'
      $ovs_service_name          = 'openvswitch-switch'
      $ovs_status_cmd            = '/etc/init.d/openvswitch-switch status'
      $lnx_vlan_tools            = 'vlan'
      $lnx_bond_tools            = 'ifenslave'
      $lnx_ethernet_tools        = 'ethtool'
      $lnx_bridge_tools          = 'bridge-utils'
      $ovs_datapath_package_name = 'openvswitch-datapath-dkms'
      $ovs_common_package_name   = 'openvswitch-switch'
      $ovs_kern_module_name      = 'openvswitch'
      $network_manager_name      = 'network-manager'
      $extra_tools               = 'iputils-arping'
      notice("L23_os ${l23_os}")
    }
    /(?i:redhat|centos)/: {
      $interfaces_dir            = '/etc/sysconfig/network-scripts'
      $interfaces_file           = undef
      $ovs_service_name          = 'openvswitch'
      $ovs_status_cmd            = '/etc/init.d/openvswitch status'
      $lnx_vlan_tools            = undef
      $lnx_bond_tools            = undef
      $lnx_ethernet_tools        = 'ethtool'
      $lnx_bridge_tools          = 'bridge-utils'
      $ovs_datapath_package_name = 'kmod-openvswitch'
      $ovs_common_package_name   = 'openvswitch'
      $ovs_kern_module_name      = 'openvswitch'
      $network_manager_name      = 'NetworkManager'
      $extra_tools               = 'iputils'
      notice("L23_os ${l23_os}")
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
      $ovs_kern_module_name      = undef
      $network_manager_name      = undef
      notice("L23_os ${::l23_os}")
    }
    default: {
      notice("L23_os UNDEF")
      fail("Unsupported OS: ${l23_os}/${::operatingsystem}")
    }
  }
  notice("L23_os XXX ${l23_os}")

}
