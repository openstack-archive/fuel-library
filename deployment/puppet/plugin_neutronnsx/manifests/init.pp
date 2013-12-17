class plugin_neutronnsx {
    if $::fuel_settings['nsx_plugin']['nicira'] {
      $nsx_config = sanitize_neutron_config($::fuel_settings, 'quantum_settings')
      $nsx_config['nicira'] = $::fuel_settings['nsx_plugin']
      class {'plugin_neutronnsx::nicira':
        neutron_config     => $nsx_config,
        ip_address         => $::internal_address,
        on_compute         => $::fuel_settings['role'] ? { 'compute' => true, 'controller' => false, default => false },
      }
    }
}
