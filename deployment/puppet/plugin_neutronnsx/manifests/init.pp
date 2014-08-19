class plugin_neutronnsx (
  $neutron_config,
  $neutron_nsx_config,
) {

  $roles = node_roles($nodes_hash, $::fuel_settings['uid'])

  if member($roles, 'controller') {
    class { 'plugin_neutronnsx::install_ovs':
      packages_url           => $neutron_nsx_config['packages_url'],
      stage                  => 'netconfig',
    }
    class { 'plugin_neutronnsx::bridges':
      neutron_nsx_config     => $neutron_nsx_config,
      ip_address             => get_connector_address($::fuel_settings),
    }
    class { 'plugin_neutronnsx::alter_neutron_server':
      neutron_config         => $neutron_config,
      neutron_nsx_config     => $neutron_nsx_config,
    }
    class { 'plugin_neutronnsx::stop_neutron_agents' :}
  }

  if member($roles, 'compute') {
    class { 'plugin_neutronnsx::install_ovs':
      packages_url           => $neutron_nsx_config['packages_url'],
      stage                  => 'netconfig',
    }
    class { 'plugin_neutronnsx::bridges':
      neutron_nsx_config     => $neutron_nsx_config,
      ip_address             => get_connector_address($::fuel_settings),
    }
    class { 'plugin_neutronnsx::stop_neutron_agents' :}
  }

}
