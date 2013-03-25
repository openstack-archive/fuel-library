class l23network::params {
  case $::osfamily {
    /(?i)debian/: {
      $ovs_service_name   = 'openvswitch-switch'
      $ovs_status_cmd     = '/etc/init.d/openvswitch-switch status'
      $ovs_packages       = ['openvswitch-datapath-dkms', 'openvswitch-switch']
      $lnx_vlan_tools     = 'vlan'
      $lnx_bond_tools     = 'ifenslave'
      $lnx_ethernet_tools = 'ethtool'
    }
    /(?i)redhat/: {
      $ovs_service_name   = 'openvswitch' #'ovs-vswitchd'
      $ovs_status_cmd     = '/etc/init.d/openvswitch status'
      $ovs_packages       = ['kmod-openvswitch', 'openvswitch']
      $lnx_vlan_tools     = 'vconfig'
      $lnx_bond_tools     = undef
      $lnx_ethernet_tools = 'ethtool'
    }
    /(?i)linux/: {
      case $::operatingsystem {
        /(?i)archlinux/: {
          $ovs_service_name   = 'openvswitch.service'
          $ovs_status_cmd     = 'systemctl status openvswitch'
          $ovs_packages       = ['aur/openvswitch']
          $lnx_vlan_tools     = 'aur/vconfig'
          $lnx_bond_tools     = 'core/ifenslave'
          $lnx_ethernet_tools = 'extra/ethtool'
        }
        default: {
          fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
        }
      }
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
