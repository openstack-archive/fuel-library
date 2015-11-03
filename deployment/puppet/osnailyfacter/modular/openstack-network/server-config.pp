notice('MODULAR: openstack-network/server-config.pp')

$use_neutron           = hiera('use_neutron', false)

class neutron { }
class { 'neutron' : }

if $use_neutron {

  $neutron_config        = hiera_hash('neutron_config')
  $neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)
  $database_vip          = hiera('database_vip')
  $management_vip        = hiera('management_vip')
  $service_endpoint      = hiera('service_endpoint', $management_vip)
  $nova_endpoint         = hiera('nova_endpoint', $management_vip)
  $nova_hash             = hiera_hash('nova', { })
  $primary_controller    = hiera('primary_controller', false)

  $neutron_db_password = $neutron_config['database']['passwd']
  $neutron_db_user     = try_get_value($neutron_config, 'database/user', 'neutron')
  $neutron_db_name     = try_get_value($neutron_config, 'database/name', 'neutron')
  $neutron_db_host     = try_get_value($neutron_config, 'database/host', $database_vip)

  $neutron_db_uri = "mysql://${neutron_db_user}:${neutron_db_password}@${neutron_db_host}/${neutron_db_name}?&read_timeout=60"

  $auth_password      = $neutron_config['keystone']['admin_password']
  $auth_user          = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $auth_tenant        = pick($neutron_config['keystone']['admin_tenant'], 'services')
  $auth_region        = hiera('region', 'RegionOne')
  $auth_endpoint_type = 'internalURL'

  $auth_api_version    = 'v2.0'
  $identity_uri        = "http://${service_endpoint}:5000/"
  #$auth_url           = "${identity_uri}${auth_api_version}"
  $nova_admin_auth_url = "http://${service_endpoint}:35357/"
  $nova_url            = "http://${nova_endpoint}:8774/v2"

  $service_workers = pick($neutron_config['workers'], min(max($::processorcount, 2), 16))

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $dvr = pick($neutron_advanced_config['neutron_dvr'], false)

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
    database_connection              => $neutron_db_uri,
    database_max_retries             => '-1',

    agent_down_time                  => '30',
    allow_automatic_l3agent_failover => true,

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

}
