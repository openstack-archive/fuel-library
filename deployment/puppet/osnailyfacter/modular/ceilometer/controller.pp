notice('MODULAR: ceilometer/controller.pp')

$default_ceilometer_hash = {
  'enabled'               => false,
  'db_password'           => 'ceilometer',
  'user_password'         => 'ceilometer',
  'metering_secret'       => 'ceilometer',
  'http_timeout'          => '600',
  'event_time_to_live'    => '604800',
  'metering_time_to_live' => '604800',
}

$verbose                  = hiera('verbose', true)
$debug                    = hiera('debug', false)
$use_syslog               = hiera('use_syslog', true)
$use_stderr               = hiera('use_stderr', false)
$syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
$nodes_hash               = hiera('nodes')
$storage_hash             = hiera('storage')
$rabbit_hash              = hiera_hash('rabbit_hash')
$management_vip           = hiera('management_vip')
$region                   = hiera('region', 'RegionOne')
$ceilometer_hash          = hiera_hash('ceilometer', $default_ceilometer_hash)
$ceilometer_region        = pick($ceilometer_hash['region'], $region)
$mongo_nodes              = get_nodes_hash_by_roles(hiera('network_metadata'), hiera('mongo_roles'))
$mongo_address_map        = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'mongo/db')

$default_mongo_hash = {
  'enabled'         => false,
}

$mongo_hash               = hiera_hash('mongo', $default_mongo_hash)

if $mongo_hash['enabled'] and $ceilometer_hash['enabled'] {
  $exteranl_mongo_hash    = hiera_hash('external_mongo')
  $ceilometer_db_user     = $exteranl_mongo_hash['mongo_user']
  $ceilometer_db_password = $exteranl_mongo_hash['mongo_password']
  $ceilometer_db_dbname   = $exteranl_mongo_hash['mongo_db_name']
  $external_mongo         = true
} else {
  $ceilometer_db_user     = 'ceilometer'
  $ceilometer_db_password = $ceilometer_hash['db_password']
  $ceilometer_db_dbname   = 'ceilometer'
  $external_mongo         = false
  $exteranl_mongo_hash    = {}
}

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

prepare_network_config(hiera('network_scheme', {}))
$api_bind_address           = get_network_role_property('ceilometer/api', 'ipaddr')

$memcached_servers = hiera('memcached_servers')

if $ceilometer_hash['enabled'] {
  if $external_mongo {
    $mongo_hosts = $exteranl_mongo_hash['hosts_ip']
    if $exteranl_mongo_hash['mongo_replset'] {
      $mongo_replicaset = $exteranl_mongo_hash['mongo_replset']
    } else {
      $mongo_replicaset = undef
    }
  } else {
    $mongo_hosts = join(values($mongo_address_map), ',')
    # MongoDB is alsways configured with replica set
    $mongo_replicaset = 'ceilometer'
  }
}

###############################################################################

if ($ceilometer_enabled) {
  class { 'openstack::ceilometer':
    verbose               => $verbose,
    debug                 => $debug,
    use_syslog            => $use_syslog,
    use_stderr            => $use_stderr,
    syslog_log_facility   => $syslog_log_facility,
    db_type               => $ceilometer_db_type,
    db_host               => $mongo_hosts,
    db_user               => $ceilometer_db_user,
    db_password           => $ceilometer_db_password,
    db_dbname             => $ceilometer_db_dbname,
    swift_rados_backend   => $swift_rados_backend,
    metering_secret       => $ceilometer_metering_secret,
    amqp_hosts            => hiera('amqp_hosts',''),
    amqp_user             => $amqp_user,
    amqp_password         => $amqp_password,
    rabbit_ha_queues      => $rabbit_ha_queues,
    keystone_host         => $service_endpoint,
    keystone_password     => $ceilometer_user_password,
    keystone_user         => $ceilometer_hash['user'],
    keystone_tenant       => $ceilometer_hash['tenant'],
    keystone_region       => $ceilometer_region,
    host                  => $api_bind_address,
    ha_mode               => $ha_mode,
    on_controller         => true,
    ext_mongo             => $external_mongo,
    mongo_replicaset      => $mongo_replicaset,
    event_time_to_live    => $ceilometer_hash['event_time_to_live'],
    metering_time_to_live => $ceilometer_hash['metering_time_to_live'],
    http_timeout          => $ceilometer_hash['http_timeout'],
  }

  ceilometer_config {
    'keystone_authtoken/memcached_servers' : value => join(any2array($memcached_servers), ',');
  }
}
