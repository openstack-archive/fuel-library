notice('MODULAR: openstack-network/agents/metadata.pp')

$use_neutron              = hiera('use_neutron', false)
$neutron_controller_roles = hiera('neutron_controller_roles', ['controller', 'primary-controller'])
$neutron_compute_roles    = hiera('neutron_compute_nodes', ['compute'])
$controller               = roles_include($neutron_controller_roles)
$compute                  = roles_include($neutron_compute_roles)
$neutron_advanced_config  = hiera_hash('neutron_advanced_configuration', { })
$dvr                      = pick($neutron_advanced_config['neutron_dvr'], false)

if $use_neutron and ($controller or ($dvr and $compute)) {
  # override neutron options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'neutron_metadata_agent_config':
    data => $override_configuration['neutron_metadata_agent_config']
  } ~> Service['neutron-metadata']
}

class neutron {}
class { 'neutron' :}

if $use_neutron and ($controller or ($dvr and $compute)) {
  $debug                   = hiera('debug', true)
  $ha_agent                = try_get_value($neutron_advanced_config, 'metadata_agent_ha', true)

  $auth_region             = hiera('region', 'RegionOne')
  $service_endpoint        = hiera('service_endpoint')
  $management_vip          = hiera('management_vip')
  $auth_api_version        = 'v2.0'
  $ssl_hash                = hiera_hash('use_ssl', {})
  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_uri      = "${admin_identity_protocol}://${admin_identity_address}:35357"
  $admin_auth_url          = "${admin_identity_uri}/${auth_api_version}"

  $neutron_config          = hiera_hash('neutron_config')

  $keystone_user           = try_get_value($neutron_config, 'keystone/admin_user', 'neutron')
  $keystone_tenant         = try_get_value($neutron_config, 'keystone/admin_tenant', 'services')
  $neutron_user_password   = try_get_value($neutron_config, 'keystone/admin_password')

  $shared_secret           = try_get_value($neutron_config, 'metadata/metadata_proxy_shared_secret')

  $nova_endpoint           = hiera('nova_endpoint', $management_vip)

  class { 'neutron::agents::metadata':
    debug          => $debug,
    auth_region    => $auth_region,
    auth_url       => $admin_auth_url,
    auth_user      => $keystone_user,
    auth_tenant    => $keystone_tenant,
    auth_password  => $neutron_user_password,
    shared_secret  => $shared_secret,
    metadata_ip    => $nova_endpoint,
    manage_service => true,
    enabled        => true,
  }

  if ($ha_agent) and !($compute) {
    $primary_controller = hiera('primary_controller')
    class { 'cluster::neutron::metadata' :
      primary => $primary_controller,
    }
  }

  # stub package for 'neutron::agents::metadata' class
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

}
