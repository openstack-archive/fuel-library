# L23network OS-aware constants
#
class l23network::params {
  $monolith_bond_providers = ['ovs']

  case $::l23_os {
    /(?i)ubuntu/: {
      $interfaces_dir             = '/etc/network/interfaces.d'
      $interfaces_file            = '/etc/network/interfaces'
      $ovs_service_name           = 'openvswitch-switch'
      $ovs_status_cmd             = '/etc/init.d/openvswitch-switch status'
      $ovs_default_file           = '/etc/default/openvswitch-switch'
      $lnx_vlan_tools             = 'vlan'
      $lnx_bond_tools             = 'ifenslave'
      $lnx_ethernet_tools         = 'ethtool'
      $lnx_bridge_tools           = 'bridge-utils'
      $ovs_datapath_package_name  = $::operatingsystemmajrelease ? {
                                        /^14\./ =>'openvswitch-datapath-dkms',
                                        default => undef
                                    }
      $ovs_common_package_name    = 'openvswitch-switch'
      $ovs_dpdk_package_name      = 'openvswitch-switch-dpdk'
      $ovs_dpdk_dkms_package_name = 'dpdk-dkms'
      $dpdk_dir                   = '/etc/dpdk'
      $dpdk_conf_file             = '/etc/dpdk/dpdk.conf'
      $dpdk_interfaces_file       = '/etc/dpdk/interfaces'
      $ovs_kern_module_name       = 'openvswitch'
      $network_manager_name       = 'network-manager'
      $extra_tools                = 'iputils-arping'
      $ovs_core_mask              = 0x1
      $ovs_socket_mem             = [256]
      $ovs_memory_channels        = 2
    }
    /(?i)redhat|centos|oraclelinux/: {
      $interfaces_dir             = '/etc/sysconfig/network-scripts'
      $interfaces_file            = undef
      $ovs_service_name           = 'openvswitch'
      $ovs_status_cmd             = '/etc/init.d/openvswitch status'
      $ovs_default_file           = undef
      $lnx_vlan_tools             = undef
      $lnx_bond_tools             = undef
      $lnx_ethernet_tools         = 'ethtool'
      $lnx_bridge_tools           = 'bridge-utils'
      $ovs_dpdk_package_name      = undef
      $ovs_dpdk_dkms_package_name = undef
      $dpdk_dir                   = undef
      $dpdk_conf_file             = undef
      $dpdk_interfaces_file       = undef
      $ovs_datapath_package_name  = $::l23_os ? {
                                      /(?i)oraclelinux/ => 'kmod-openvswitch-uek',
                                      default           => 'kmod-openvswitch',
                                    }
      $ovs_common_package_name    = 'openvswitch'
      $ovs_kern_module_name       = 'openvswitch'
      $network_manager_name       = 'NetworkManager'
      $extra_tools                = 'iputils'
      $ovs_core_mask              = 0x1
      $ovs_socket_mem             = [256]
      $ovs_memory_channels        = 2
    }
    /(?i)darwin/: {
      $interfaces_dir             = '/tmp/1'
      $interfaces_file            = undef
      $ovs_service_name           = undef
      $ovs_default_file           = undef
      $lnx_vlan_tools             = undef
      $lnx_bond_tools             = undef
      $lnx_ethernet_tools         = undef
      $lnx_bridge_tools           = undef
      $ovs_dpdk_package_name      = undef
      $ovs_dpdk_dkms_package_name = undef
      $dpdk_dir                   = undef
      $dpdk_conf_file             = undef
      $dpdk_interfaces_file       = undef
      $ovs_datapath_package_name  = undef
      $ovs_common_package_name    = undef
      $ovs_kern_module_name       = undef
      $network_manager_name       = undef
      $ovs_core_mask              = undef
      $ovs_socket_mem             = undef
      $ovs_memory_channels        = undef
    }
    default: {
      fail("Unsupported OS: ${l23_os}/${::operatingsystem}")
    }
  }
}
