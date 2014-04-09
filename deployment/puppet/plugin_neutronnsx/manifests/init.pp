class plugin_neutronnsx {
    if has_key($::fuel_settings, 'nsx_plugin'){
      if $::fuel_settings['nsx_plugin']['use_nsx'] {
	$neutron_nsx_config = sanitize_neutron_config($::fuel_settings, 'quantum_settings')
	$neutron_nsx_config['nsx'] = $::fuel_settings['nsx_plugin']

	class { 'plugin_neutronnsx::vmware_nsx':
	  neutron_config     => $neutron_nsx_config,
	  ip_address         => get_connector_address($::fuel_settings),
	  on_compute         => $::fuel_settings['role'] ? { 'compute' => true, 'controller' => false, default => false },
	}
      }
    }
}
