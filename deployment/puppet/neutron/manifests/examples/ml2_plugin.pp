class neutron::examples::ml2_plugin (
    $fuel_settings,
) {
  class {'l23network': use_ovs=>true}
  prepare_network_config($fuel_settings['network_scheme'])
  $sdn = generate_network_config()

  $neutron_config = sanitize_neutron_config($fuel_settings, 'quantum_settings')
  class { 'neutron::plugins::ml2_plugin':
    neutron_config => $neutron_config
  }

}
###