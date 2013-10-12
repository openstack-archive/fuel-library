#
# == parameters
#  * quantum_config: Quantum config hash.
#  * quantum_auth_strategy: auth strategy used by quantum.

class nova::network::quantum (
  $quantum_config   = {},
  $quantum_connection_host,
  $quantum_auth_strategy = 'keystone',
) {

  if $quantum_connection_host != 'localhost' {
    nova_config { 'DEFAULT/quantum_connection_host': value => $quantum_connection_host }
  }

  nova_config {
    'DEFAULT/network_api_class':         value => 'nova.network.quantumv2.api.API';  # quantumv2 !!! not a quantum.v2
    'DEFAULT/quantum_auth_strategy':     value => $quantum_auth_strategy;
    'DEFAULT/quantum_url':               value => $quantum_config['server']['api_url'];
    'DEFAULT/quantum_admin_tenant_name': value => $quantum_config['keystone']['admin_tenant_name'];
    'DEFAULT/quantum_admin_username':    value => $quantum_config['keystone']['admin_user'];
    'DEFAULT/quantum_admin_password':    value => $quantum_config['keystone']['admin_password'];
    'DEFAULT/quantum_admin_auth_url':    value => $quantum_config['keystone']['auth_url'];
  }
}

# vim: set ts=2 sw=2 et :