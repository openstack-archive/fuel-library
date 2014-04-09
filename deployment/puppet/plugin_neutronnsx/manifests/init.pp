class plugin_neutronnsx {
#  if $::fuel_settings['nsx_plugin']['metadata']['enabled'] {
    $neutron_config = sanitize_neutron_config($::fuel_settings, 'quantum_settings')
    $neutron_nsx_config = $::fuel_settings['nsx_plugin']

    $roles = node_roles($nodes_hash, $::fuel_settings['uid'])
    if member($roles, 'controller') {
      class { 'plugin_neutronnsx::neutron_agent_vmware':
        neutron_nsx_config     => $neutron_nsx_config,
        ip_address         => get_connector_address($::fuel_settings),
      }
    }
    
    if member($roles, 'compute') {
      class { 'plugin_neutronnsx::neutron_agent_vmware':
        neutron_nsx_config     => $neutron_nsx_config,
        ip_address         => get_connector_address($::fuel_settings),
      }
      class { 'plugin_neutronnsx::alter_neutron_server':
        neutron_config     => $neutron_config,
        neutron_nsx_config     => $neutron_nsx_config,
      }
    }

    if member($roles, 'primary_controller') {
      class { 'plugin_neutronnsx::neutron_agent_vmware':
        neutron_nsx_config     => $neutron_nsx_config,
        ip_address         => get_connector_address($::fuel_settings),
      }
      class { 'plugin_neutronnsx::primary_controller':
        neutron_nsx_config     => $neutron_nsx_config,
      }
    }
#  }
}
