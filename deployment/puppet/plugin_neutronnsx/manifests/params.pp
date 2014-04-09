class plugin_neutronnsx::params {
  case $::osfamily {
    /(?i)debian/: {
       $neutron_plugin_package = 'neutron-plugin-nicira'
    }
    /(?i)redhat/: {
       $neutron_plugin_package = 'openstack-neutron-nicira'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
