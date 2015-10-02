notice('MODULAR: openstack-network/agents/l3.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  $debug                   = hiera('debug', true)
  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent                = try_get_value($neutron_advanced_config, 'metadata_agent_ha', true)

  $auth_region             = hiera('region', 'RegionOne')
  $service_endpoint        = hiera('service_endpoint')
  $auth_url                = "http://${service_endpoint}:35357/v2.0"

  $keystone_user           = try_get_value($neutron_config, 'keystone/admin_user', 'neutron')
  $keystone_tenant         = try_get_value($neutron_config, 'keystone/admin_tenant', 'services')
  $neutron_user_password   = try_get_value($neutron_config, 'keystone/admin_password')

  $shared_secret           = try_get_value($neutron_config, 'metadata/metadata_proxy_shared_secret')

  $management_vip          = hiera('management_vip')
  $nova_endpoint           = hiera('nova_endpoint', $management_vip)

  class { 'neutron::agents::metadata':
    debug          => $debug,
    auth_region    => $auth_region,
    auth_url       => $auth_url,
    auth_user      => $keystone_user,
    auth_tenant    => $keystone_tenant,
    auth_password  => $neutron_user_password,
    shared_secret  => $shared_secret,
    metadata_ip    => $nova_endpoint,
    manage_service => true,
    enabled        => true,

  }

#if $ha_agents {
#  class { 'cluster::neutron::metadata' :}
#}

}
