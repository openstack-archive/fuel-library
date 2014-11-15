class l23network::params {
  if is_float($::kernelmajversion) {
    $kernelmajversion_f = 0 + $::kernelmajversion  # just a hack for convert string to float
  } else {
    $kernelmajversion_f = -1
  }

  case $::osfamily {
    /(?i)debian/: {
      $ovs_service_name   = 'openvswitch-switch'
      $ovs_status_cmd     = '/etc/init.d/openvswitch-switch status'
      $lnx_vlan_tools     = 'vlan'
      $lnx_bond_tools     = 'ifenslave'
      $lnx_ethernet_tools = 'ethtool'
      $ovs_datapath_package_name = $kernelmajversion_f > 0 and $kernelmajversion_f < 3.13  ?  'openvswitch-datapath-lts-saucy-dkms'  :  false
      $ovs_common_package_name   = 'openvswitch-switch'
    }
    /(?i)redhat/: {
      $ovs_service_name   = 'openvswitch'
      $ovs_status_cmd     = '/etc/init.d/openvswitch status'
      $lnx_vlan_tools     = 'vconfig'
      $lnx_bond_tools     = undef
      $lnx_ethernet_tools = 'ethtool'
      $ovs_datapath_package_name = $kernelmajversion_f > 0 and $kernelmajversion_f < 3.10  ?  'kmod-openvswitch'  :  false
      $ovs_common_package_name   = 'openvswitch'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
