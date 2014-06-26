class neutron::examples::ml2_agent (
    $fuel_settings,
) {
  class {'l23network': use_ovs=>true}
  prepare_network_config($fuel_settings['network_scheme'])
  $sdn = generate_network_config()

  $neutron_config = sanitize_neutron_config($fuel_settings, 'quantum_settings')
  class { 'neutron::agents::ml2_agent':
    neutron_config => $neutron_config
  }

}
###