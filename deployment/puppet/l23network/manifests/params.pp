class l23network::params {
  case $::osfamily {
    /(?i)debian/: {
      $ovs_service_name   = 'openvswitch-switch'
      $ovs_status_cmd     = '/etc/init.d/openvswitch-switch status'
      $lnx_vlan_tools     = 'vlan'
      $lnx_bond_tools     = 'ifenslave'
      $lnx_ethernet_tools = 'ethtool'
    }
    /(?i)redhat/: {
      $ovs_service_name   = 'openvswitch' #'ovs-vswitchd'
      $ovs_status_cmd     = '/etc/init.d/openvswitch status'
      $lnx_vlan_tools     = 'vconfig'
      $lnx_bond_tools     = undef
      $lnx_ethernet_tools = 'ethtool'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
