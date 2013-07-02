#
# == parameters
#  * quantum_admin_password: password for quantum keystone user.
#  * quantum_auth_strategy: auth strategy used by quantum.
#  * quantum_connection_host
#  * quantum_url
#  * quantum_admin_tenant_name
#  * quantum_admin_username
#  * quantum_admin_auth_url
class nova::network::quantum (
  #$fixed_range,
  $quantum_admin_password,
  #$use_dhcp                  = 'True',
  #$public_interface          = undef,
  $quantum_connection_host   = 'localhost',
  $quantum_auth_strategy     = 'keystone',
  $quantum_url               = 'http://127.0.0.1:9696',
  $quantum_admin_tenant_name = 'services',
  $quantum_admin_username    = 'quantum',
  $quantum_admin_auth_url    = 'http://127.0.0.1:35357/v2.0',
  $public_interface          = undef,
) {

  if $public_interface {
    nova_config { 'DEFAULT/public_interface': value => $public_interface }
  }

  if $quantum_connection_host != 'localhost' {
    nova_config { 'DEFAULT/quantum_connection_host': value => $quantum_connection_host }
  }

  nova_config {
##    'DEFAULT/fixed_range':               value => $fixed_range;
##    'DEFAULT/quantum_use_dhcp':          value => $use_dhcp;
    'DEFAULT/quantum_auth_strategy':     value => $quantum_auth_strategy;
    'DEFAULT/network_api_class':         value => 'nova.network.quantumv2.api.API';
    'DEFAULT/quantum_url':               value => $quantum_url;
    'DEFAULT/quantum_admin_tenant_name': value => $quantum_admin_tenant_name;
    'DEFAULT/quantum_admin_username':    value => $quantum_admin_username;
    'DEFAULT/quantum_admin_password':    value => $quantum_admin_password;
    'DEFAULT/quantum_admin_auth_url':    value => $quantum_admin_auth_url;
  }
}
