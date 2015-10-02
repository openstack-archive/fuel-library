notice('MODULAR: openstack-network/server.pp')

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

  $auth_url     = "http://${service_endpoint}:35357/v2.0"
  $identity_uri = "http://${service_endpoint}:35357"
  $nova_url     = "http://${nova_endpoint}:8774/v2"

  $service_workers = pick($neutron_config['workers'], min(max($::processorcount, 2), 16))

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $dvr = pick($neutron_advanced_config['neutron_dvr'], false)

  $nova_auth_user          = $nova_hash['user']
  $nova_auth_password      = $nova_hash['user_password']
  $nova_auth_tenant        = $nova_hash['tenant']
  $nova_auth_region        = hiera('region', 'RegionOne')

  class { 'neutron::server':
    sync_db                          =>  $primary_controller,

    auth_password                    => $auth_password,
    auth_tenant                      => $auth_tenant,
    auth_region                      => $auth_region,
    auth_user                        => $auth_user,
    auth_uri                         => $auth_url,
    identity_uri                     => $identity_uri,

    database_retry_interval          => '2',
    database_connection              => $neutron_db_uri,
    database_max_retries             => '-1',

    agent_down_time                  => '30',
    allow_automatic_l3agent_failover => true,

    api_workers                      => $service_workers,
    rpc_workers                      => $service_workers,

    router_distributed               => $dvr,
    enabled                          => $neutron_server_enable,
  }

  include neutron::params
  tweaks::ubuntu_service_override { "$::neutron::params::server_service":
    package_name => $neutron::params::server_package ? {
      false   => $neutron::params::package_name,
      default => $neutron::params::server_package
    }
  }

  class { 'neutron::server::notifications':
    nova_url                => $nova_url,
    nova_admin_auth_url     => $auth_url,
    nova_admin_username     => $nova_auth_user,
    nova_admin_tenant_name  => $nova_auth_tenant,
    nova_admin_password     => $nova_auth_password,
    nova_region_name        => $nova_auth_region,
  }

# In Juno Neutron API ready for answer not yet when server starts.
  exec { 'waiting-for-neutron-api':
    environment => [
      "OS_TENANT_NAME=${auth_tenant}",
      "OS_USERNAME=${auth_user}",
      "OS_PASSWORD=${auth_password}",
      "OS_AUTH_URL=${auth_url}",
      "OS_REGION_NAME=${auth_region}",
      "OS_ENDPOINT_TYPE=${auth_endpoint_type}",
    ],
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    tries       => '30',
    try_sleep   => '4',
    command     => 'neutron net-list --http-timeout=4 2>&1 > /dev/null',
    provider    => 'shell'
  }

  Service['neutron-server'] -> Exec<| title == 'waiting-for-neutron-api' |>

  #===================================================================

}
