class plugin_neutronnsx::params {
  $neutron_plugin_ovs_agent = 'neutron-plugin-openvswitch-agent'

  case $::osfamily {
    /(?i)debian/: {
      $neutron_plugin_package = 'neutron-plugin-vmware'
      $ml2_server_package = 'neutron-plugin-ml2'
    }
    /(?i)redhat/: {
      $neutron_plugin_package = 'openstack-neutron-vmware'
      $ml2_server_package = 'openstack-neutron-ml2'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
