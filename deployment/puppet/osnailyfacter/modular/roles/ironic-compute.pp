notice('MODULAR: ironic-compute.pp')

$ironic_hash                    = hiera_hash('ironic', {})
$nova_hash                      = hiera_hash('nova', {})
$ceilometer_hash                = hiera_hash('ceilometer',{})
$auto_assign_floating_ip        = hiera('auto_assign_floating_ip', false)
$public_int                     = hiera('public_int', undef)
$management_vip                 = hiera('management_vip')
$service_endpoint               = hiera('service_endpoint', $management_vip)
$database_vip                   = hiera('database_vip', $service_endpoint)
$keystone_endpoint              = hiera('keystone_endpoint', $service_endpoint)
$neutron_endpoint               = hiera('neutron_endpoint', $service_endpoint)
$ironic_endpoint                = hiera('ironic_endpoint', $service_endpoint)
$glance_api_servers             = hiera('glance_api_servers', "${service_endpoint}:9292")
$debug                          = hiera('debug', false)
$verbose                        = hiera('verbose', true)
$use_syslog                     = hiera('use_syslog', true)
$syslog_log_facility_ironic     = hiera('syslog_log_facility_ironic', 'LOG_LOCAL0')
$syslog_log_facility_nova       = hiera('syslog_log_facility_nova', 'LOG_LOCAL6')
$amqp_hosts                     = hiera('amqp_hosts')
$rabbit_hash                    = hiera('rabbit_hash')
$rabbit_ha_queues               = hiera('rabbit_ha_queues')
$nova_rate_limits               = hiera('nova_rate_limits')
$nova_report_interval           = hiera('nova_report_interval')
$nova_service_down_time         = hiera('nova_service_down_time')
$storage_hash                   = hiera_hash('storage', {})
$neutron_config                 = hiera_hash('quantum_settings')
#$network_config                = hiera('network_config')
$network_manager                = hiera('network_manager', {})
$neutron_net                    = $neutron_config['predefined_networks']['baremetal']

$ironic_tenant                  = pick($ironic_hash['tenant'],'services')
$ironic_user                    = pick($ironic_hash['user'],'ironic')
$ironic_user_password           = $ironic_hash['user_password']

$db_host                        = pick($nova_hash['db_host'], $database_vip)
$db_user                        = pick($nova_hash['db_user'], 'nova')
$db_name                        = pick($nova_hash['db_name'], 'nova')
$db_password                    = pick($nova_hash['db_password'], 'nova')
$database_connection            = "mysql://${db_name}:${db_password}@${db_host}/${db_name}?read_timeout=60"

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')


  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ! defined( Resources[nova_config] ) {
    if ($purge_nova_config) {
      resources { 'nova_config':
        purge => true,
      }
    }
  }
  $controllers                    = hiera('controllers')
  $controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
  $controller_nodes = ipsort(values($controller_internal_addresses))
  $cache_server_ip = $controller_nodes
  $memcached_addresses =  suffix($cache_server_ip, inline_template(":<%= @cache_server_port %>"))
  $notify_on_state_change = 'vm_and_task_state'

  class { 'nova':
      install_utilities      => false,
      ensure_package         => installed,
      database_connection    => $database_connection,
      rpc_backend            => 'nova.openstack.common.rpc.impl_kombu',
      #FIXME(bogdando) we have to split amqp_hosts until all modules synced
      rabbit_hosts           => split($amqp_hosts, ','),
      rabbit_userid          => $rabbit_hash['user'],
      rabbit_password        => $rabbit_hash['password'],
      image_service          => 'nova.image.glance.GlanceImageService',
      glance_api_servers     => $glance_api_servers,
      verbose                => $verbose,
      debug                  => $debug,
      use_syslog             => $use_syslog,
      log_facility           => $syslog_log_facility_nova,
      state_path             => $nova_hash['state_path'],
      report_interval        => $nova_report_interval,
      service_down_time      => $nova_service_down_time,
      notify_on_state_change => $notify_on_state_change,
      memcached_servers      => $memcached_addresses,
  }


  class { '::nova::compute':
    ensure_package                => installed,
    enabled                       => true,
    vnc_enabled                   => false,
    force_config_drive            => $nova_hash['force_config_drive'],
    #NOTE(bogdando) default became true in 4.0.0 puppet-nova (was false)
    neutron_enabled               => ($network_provider == 'neutron'),
    default_availability_zone     => $nova_hash['default_availability_zone'],
    default_schedule_zone         => $nova_hash['default_schedule_zone'],
  }


class { 'nova::compute::ironic':
  admin_url         => "http://${keystone_endpoint}:35357/v2.0",
  admin_user        => $ironic_user,
  admin_tenant_name => $ironic_tenant,
  admin_passwd      => $ironic_user_password,
  api_endpoint      => "http://${ironic_endpoint}:6385/v1",
}

class { 'nova::network::neutron':
  neutron_admin_password => $neutron_config['keystone']['admin_password'],
  neutron_url            => "http://${neutron_endpoint}:9696",
  neutron_admin_auth_url => "http://${keystone_endpoint}:35357/v2.0",
}
