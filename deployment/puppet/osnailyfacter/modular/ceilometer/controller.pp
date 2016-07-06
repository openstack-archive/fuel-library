notice('MODULAR: ceilometer/controller.pp')

$default_ceilometer_hash = {
  'enabled'                    => false,
  'db_password'                => 'ceilometer',
  'user_password'              => 'ceilometer',
  'metering_secret'            => 'ceilometer',
  'http_timeout'               => '600',
  'event_time_to_live'         => '604800',
  'metering_time_to_live'      => '604800',
  'alarm_history_time_to_live' => '604800',
}

$ceilometer_hash          = hiera_hash('ceilometer', $default_ceilometer_hash)
$verbose                  = pick($ceilometer_hash['verbose'], hiera('verbose', true))
$debug                    = pick($ceilometer_hash['debug'], hiera('debug', false))
$default_log_levels       = hiera_hash('default_log_levels')
$use_syslog               = hiera('use_syslog', true)
$use_stderr               = hiera('use_stderr', false)
$syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
$nodes_hash               = hiera('nodes')
$storage_hash             = hiera('storage')
$rabbit_hash              = hiera_hash('rabbit_hash')
$management_vip           = hiera('management_vip')
$region                   = hiera('region', 'RegionOne')
$ceilometer_region        = pick($ceilometer_hash['region'], $region)
$mongo_nodes              = get_nodes_hash_by_roles(hiera_hash('network_metadata'), hiera('mongo_roles'))
$mongo_address_map        = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'mongo/db')
$primary_controller       = hiera('primary_controller')

$ceilometer_enabled         = $ceilometer_hash['enabled']
$ceilometer_user_password   = $ceilometer_hash['user_password']
$ceilometer_metering_secret = $ceilometer_hash['metering_secret']
$ceilometer_db_type         = 'mongodb'
$swift_rados_backend        = $storage_hash['objects_ceph']
$amqp_password              = $rabbit_hash['password']
$amqp_user                  = $rabbit_hash['user']
$rabbit_ha_queues           = true
$service_endpoint           = hiera('service_endpoint')
$ha_mode                    = pick($ceilometer_hash['ha_mode'], true)
$ssl_hash                   = hiera_hash('use_ssl', {})
$workers_max                = hiera('workers_max', 16)
$service_workers            = pick($ceilometer_hash['workers'],
                                min(max($::processorcount, 2), $workers_max))

prepare_network_config(hiera_hash('network_scheme', {}))
$api_bind_address           = get_network_role_property('ceilometer/api', 'ipaddr')

$keystone_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$keystone_endpoint = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

$memcached_servers = hiera('memcached_servers')

# Database related items
$default_mongo_hash = {
  'enabled' => false,
}

$mongo_hash = hiera_hash('mongo', $default_mongo_hash)
$db_type    = 'mongodb'

if $mongo_hash['enabled'] and $ceilometer_hash['enabled'] {
  $external_mongo_hash = hiera_hash('external_mongo')
  $db_user             = $external_mongo_hash['mongo_user']
  $db_password         = $external_mongo_hash['mongo_password']
  $db_name             = $external_mongo_hash['mongo_db_name']
  $db_host             = $external_mongo_hash['hosts_ip']
  if $external_mongo_hash['mongo_replset'] {
    $mongo_replicaset  = $external_mongo_hash['mongo_replset']
  } else {
    $mongo_replicaset  = undef
  }
} else {
  $db_user             = 'ceilometer'
  $db_password         = $ceilometer_hash['db_password']
  $db_name             = 'ceilometer'
  $db_host             = join(values($mongo_address_map), ',')
  # MongoDB is alsways configured with replica set
  $mongo_replicaset    = 'ceilometer'
}

$db_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_name}?readpreference=primaryPreferred"

###############################################################################

if ($ceilometer_enabled) {
  class { 'openstack::ceilometer':
    verbose                    => $verbose,
    debug                      => $debug,
    use_syslog                 => $use_syslog,
    use_stderr                 => $use_stderr,
    syslog_log_facility        => $syslog_log_facility,
    default_log_levels         => $default_log_levels,
    db_connection              => $db_connection,
    swift_rados_backend        => $swift_rados_backend,
    metering_secret            => $ceilometer_metering_secret,
    amqp_hosts                 => hiera('amqp_hosts',''),
    amqp_user                  => $amqp_user,
    amqp_password              => $amqp_password,
    rabbit_ha_queues           => $rabbit_ha_queues,
    keystone_protocol          => $keystone_protocol,
    keystone_host              => $keystone_endpoint,
    keystone_password          => $ceilometer_user_password,
    keystone_user              => $ceilometer_hash['user'],
    keystone_tenant            => $ceilometer_hash['tenant'],
    keystone_region            => $ceilometer_region,
    host                       => $api_bind_address,
    ha_mode                    => $ha_mode,
    primary_controller         => $primary_controller,
    on_controller              => true,
    mongo_replicaset           => $mongo_replicaset,
    alarm_history_time_to_live => $ceilometer_hash['alarm_history_time_to_live'],
    event_time_to_live         => $ceilometer_hash['event_time_to_live'],
    metering_time_to_live      => $ceilometer_hash['metering_time_to_live'],
    http_timeout               => $ceilometer_hash['http_timeout'],
    api_workers                => $service_workers,
    collector_workers          => $service_workers,
    notification_workers       => $service_workers,
  }

  ceilometer_config {
    'keystone_authtoken/memcached_servers' : value => join(any2array($memcached_servers), ',');
  }
}
