#
# == parameters
#  * neutron_config: Quantum config hash.
#  * neutron_auth_strategy: auth strategy used by neutron.

class nova::network::neutron (
  $neutron_config   = {},
  $neutron_connection_host,
  $neutron_auth_strategy = 'keystone',
) {

  if $neutron_connection_host != 'localhost' {
    nova_config { 'DEFAULT/neutron_connection_host': value => $neutron_connection_host }
  }

  nova_config {
    'DEFAULT/network_api_class':         value => 'nova.network.neutronv2.api.API';  # neutronv2 !!! not a neutron.v2
    'DEFAULT/neutron_auth_strategy':     value => $neutron_auth_strategy;
    'DEFAULT/neutron_url':               value => $neutron_config['server']['api_url'];
    'DEFAULT/neutron_admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'DEFAULT/neutron_admin_username':    value => $neutron_config['keystone']['admin_user'];
    'DEFAULT/neutron_admin_password':    value => $neutron_config['keystone']['admin_password'];
    'DEFAULT/neutron_admin_auth_url':    value => $neutron_config['keystone']['auth_url'];
  }
}

# vim: set ts=2 sw=2 et :