class plugin_neutronnsx::params {
  $neutron_plugin_ovs_agent = 'neutron-plugin-openvswitch-agent'

  case $::osfamily {
    /(?i)debian/: {
      $neutron_plugin_package = 'neutron-plugin-vmware'
    }
    /(?i)redhat/: {
      $neutron_plugin_package = 'openstack-neutron-vmware'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
