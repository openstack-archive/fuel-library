notice('ceilometer/controller.pp')

$verbose                  = hiera('verbose', true)
$debug                    = hiera('debug', false)
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
$nodes_hash               = hiera('nodes')
$storage_hash             = hiera('storage')
$amqp_hosts               = hiera('amqp_hosts')
$rabbit_hash              = hiera('rabbit_hash')
$management_vip           = hiera('management_vip')
$internal_address         = hiera('internal_address')

$default_ceilometer_hash = {
  'enabled'         => false,
  'db_password'     => 'ceilometer',
  'user_password'   => 'ceilometer',
  'metering_secret' => 'ceilometer',
}

$default_mongo_hash = {
  'enabled'         => false,
}

$ceilometer_hash          = hiera('ceilometer', $default_ceilometer_hash)
$mongo_hash               = hiera('mongo', $default_mongo_hash)

if $mongo_hash['enabled'] and $ceilometer_hash['enabled'] {
  $exteranl_mongo_hash    = hiera('external_mongo')
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
$ceilometer_db_host         = $mongo_hosts
$swift_rados_backend        = $storage_hash['objects_ceph']
$amqp_password              = $rabbit_hash['password']
$amqp_user                  = $rabbit_hash['user']
$rabbit_ha_queues           = true
$service_endpoint           = $management_vip
$api_bind_address           = $internal_address
$ha_mode                    = true

if $ceilometer_hash['enabled'] {
  if $external_mongo {
    $mongo_hosts = $exteranl_mongo_hash['hosts_ip']
    if $exteranl_mongo_hash['mongo_replset'] {
      $mongo_replicaset = $exteranl_mongo_hash['mongo_replset']
    } else {
      $mongo_replicaset = undef
    }
  } else {
    $mongo_hosts = mongo_hosts($nodes_hash)
    if size(mongo_hosts($nodes_hash, 'array', 'mongo')) > 1 {
      $mongo_replicaset = 'ceilometer'
    } else {
      $mongo_replicaset = undef
    }
  }
}

###############################################################################

if ($ceilometer_enabled) {
  class { 'openstack::ceilometer':
    verbose              => $verbose,
    debug                => $debug,
    use_syslog           => $use_syslog,
    syslog_log_facility  => $syslog_log_facility,
    db_type              => $ceilometer_db_type,
    db_host              => $ceilometer_db_host,
    db_user              => $ceilometer_db_user,
    db_password          => $ceilometer_db_password,
    db_dbname            => $ceilometer_db_dbname,
    swift_rados_backend  => $swift_rados_backend,
    metering_secret      => $ceilometer_metering_secret,
    amqp_hosts           => $amqp_hosts,
    amqp_user            => $amqp_user,
    amqp_password        => $amqp_password,
    rabbit_ha_queues     => $rabbit_ha_queues,
    keystone_host        => $service_endpoint,
    keystone_password    => $ceilometer_user_password,
    host                 => $api_bind_address,
    ha_mode              => $ha_mode,
    on_controller        => true,
    ext_mongo            => $external_mongo,
    mongo_replicaset     => $mongo_replicaset,
  }
}
