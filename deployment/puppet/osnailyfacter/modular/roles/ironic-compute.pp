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
$syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
$syslog_log_facility_ceilometer = hiera('syslog_log_facility_ceilometer','LOG_LOCAL0')
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
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

class { 'openstack::compute':
  public_interface               => $public_int ? { undef=>'', default=>$public_int},
  private_interface              => false,
  internal_address               => '127.0.0.1',
  libvirt_type                   => 'ironic',
  network_manager                => $network_manager,
  database_connection            => $database_connection,
  amqp_hosts                     => $amqp_hosts,
  amqp_user                      => $rabbit_hash['user'],
  amqp_password                  => $rabbit_hash['password'],
  rabbit_ha_queues               => $rabbit_ha_queues,
  auto_assign_floating_ip        => $auto_assign_floating_ip,
  glance_api_servers             => $glance_api_servers,
  debug                          => $debug,
  verbose                        => $verbose,
  vnc_enabled                    => false,
  nova_user_password             => $nova_hash[user_password],
  cache_server_ip                => $controller_nodes,
  cinder                         => false,
  ceilometer                     => $ceilometer_hash[enabled],
  ceilometer_metering_secret     => $ceilometer_hash[metering_secret],
  ceilometer_user_password       => $ceilometer_hash[user_password],
  network_provider               => 'neutron',
  neutron_user_password          => $neutron_config['keystone']['admin_password'],
  base_mac                       => $neutron_config['L2']['base_mac'],
  use_syslog                     => $use_syslog,
  syslog_log_facility            => $syslog_log_facility_nova,
  syslog_log_facility_neutron    => $syslog_log_facility_neutron,
  syslog_log_facility_ceilometer => $syslog_log_facility_ceilometer,
  nova_rate_limits               => $nova_rate_limits,
  nova_report_interval           => $nova_report_interval,
  nova_service_down_time         => $nova_service_down_time,
  state_path                     => $nova_hash['state_path'],
  storage_hash                   => $storage_hash,
  reserved_host_memory           => '0',
}

class { 'nova::compute::ironic':
  admin_url                      => "http://${keystone_endpoint}:35357/v2.0",
  admin_user                     => $ironic_user,
  admin_tenant_name              => $ironic_tenant,
  admin_passwd                   => $ironic_user_password,
  api_endpoint                   => "http://${ironic_endpoint}:6385/v1",
}

class { 'nova::network::neutron':
  neutron_admin_password         => $neutron_config['keystone']['admin_password'],
  neutron_url                    => "http://${neutron_endpoint}:9696",
  neutron_admin_auth_url         => "http://${keystone_endpoint}:35357/v2.0",
}
