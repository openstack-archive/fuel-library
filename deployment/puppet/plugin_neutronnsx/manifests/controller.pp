class plugin_neutronnsx::controller (
  $neutron_config,
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

  class { 'plugin_neutronnsx::alter_neutron_server':
    neutron_config         => $neutron_config,
    neutron_nsx_config     => $neutron_nsx_config,
  }

  class { 'plugin_neutronnsx::stop_neutron_agents' :}

}
