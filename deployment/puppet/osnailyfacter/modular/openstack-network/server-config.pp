notice('MODULAR: openstack-network/server-config.pp')

$use_neutron = hiera('use_neutron', false)

class neutron { }
class { 'neutron' : }

if $use_neutron {

  $neutron_config          = hiera_hash('neutron_config')
  $neutron_server_enable   = pick($neutron_config['neutron_server_enable'], true)
  $database_vip            = hiera('database_vip')
  $management_vip          = hiera('management_vip')
  $service_endpoint        = hiera('service_endpoint', $management_vip)
  $nova_endpoint           = hiera('nova_endpoint', $management_vip)
  $nova_hash               = hiera_hash('nova', { })
  $primary_controller      = hiera('primary_controller', false)

  $db_type     = 'mysql'
  $db_password = $neutron_config['database']['passwd']
  $db_user     = try_get_value($neutron_config, 'database/user', 'neutron')
  $db_name     = try_get_value($neutron_config, 'database/name', 'neutron')
  $db_host     = try_get_value($neutron_config, 'database/host', $database_vip)
  # LP#1526938 - python-mysqldb supports this, python-pymysql does not
  if $::os_package_type == 'debian' {
    $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
  } else {
    $extra_params = { 'charset' => 'utf8' }
  }
  $db_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

  $auth_password           = $neutron_config['keystone']['admin_password']
  $auth_user               = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $auth_tenant             = pick($neutron_config['keystone']['admin_tenant'], 'services')
  $auth_region             = hiera('region', 'RegionOne')
  $auth_endpoint_type      = 'internalURL'

  $ssl_hash                = hiera_hash('use_ssl', {})

  $internal_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_endpoint  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

  $admin_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

  $nova_internal_protocol  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
  $nova_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])

  $auth_api_version        = 'v2.0'
  $identity_uri            = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"
  $nova_admin_auth_url     = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/"
  $nova_url                = "${nova_internal_protocol}://${nova_internal_endpoint}:8774/v2"

  $service_workers         = pick($neutron_config['workers'], min(max($::processorcount, 2), 16))

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $dvr                     = pick($neutron_advanced_config['neutron_dvr'], false)
  $l3_ha                   = pick($neutron_advanced_config['neutron_l3_ha'], false)
  $l3agent_failover        = $l3_ha ? { true => false, default => true}

  $nova_auth_user          = pick($nova_hash['user'], 'nova')
  $nova_auth_password      = $nova_hash['user_password']
  $nova_auth_tenant        = pick($nova_hash['tenant'], 'services')

  class { 'neutron::server':
    sync_db                          =>  false,

    auth_password                    => $auth_password,
    auth_tenant                      => $auth_tenant,
    auth_region                      => $auth_region,
    auth_user                        => $auth_user,
    identity_uri                     => $identity_uri,
    auth_uri                         => $identity_uri,

    database_retry_interval          => '2',
    database_connection              => $db_connection,
    database_max_retries             => '-1',

    agent_down_time                  => '30',
    allow_automatic_l3agent_failover => $l3agent_failover,
    l3_ha                            => $l3_ha,
    min_l3_agents_per_router         => 2,
    max_l3_agents_per_router         => 0,

    api_workers                      => $service_workers,
    rpc_workers                      => $service_workers,

    router_distributed               => $dvr,
    enabled                          => false, #$neutron_server_enable,
    manage_service                   => true,
  }

  include neutron::params
  tweaks::ubuntu_service_override { "$::neutron::params::server_service":
    package_name => $neutron::params::server_package ? {
      false   => $neutron::params::package_name,
      default => $neutron::params::server_package
    }
  }

  class { 'neutron::server::notifications':
    nova_url     => $nova_url,
    auth_url     => $nova_admin_auth_url,
    username     => $nova_auth_user,
    tenant_name  => $nova_auth_tenant,
    password     => $nova_auth_password,
    region_name  => $auth_region,
  }

  # Stub for Nuetron package
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

  # override neutron options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'neutron_api_config':
    data => $override_configuration['neutron_api_config']
  }
  override_resources { 'neutron_config':
    data => $override_configuration['neutron_config']
  }

}
