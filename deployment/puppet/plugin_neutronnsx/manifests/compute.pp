class plugin_neutronnsx::compute (
  $neutron_nsx_config,
  $connector_address,
) {

  class { 'plugin_neutronnsx::install_ovs':
    packages_url           => $neutron_nsx_config['packages_url'],
    stage                  => 'netconfig',
  }

  class { 'plugin_neutronnsx::bridges':
    neutron_nsx_config     => $neutron_nsx_config,
    ip_address             => $connector_address,
  }

}
