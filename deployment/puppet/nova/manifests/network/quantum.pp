class nova::network::quantum (
  $fixed_range,
  $use_dhcp                = 'True',
  $public_interface        = undef,
  $quantum_connection_host = localhost,
) {

  if $public_interface {
    nova_config { 'public_interface': value => $public_interface }
  }

  if $quantum_host != 'localhost' {
    nova_config { 'quantum_connection_host': value => $quantum_connection_host }
  }

  nova_config { 
    'network_manager': value => 'nova.network.quantum.manager.QuantumManager';
    'fixed_range': value => $fixed_range;
    'quantum_use_dhcp': value => $use_dhcp;
  }
}
