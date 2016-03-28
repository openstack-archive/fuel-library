notice('MODULAR: openstack-cinder.pp')

#Network stuff
prepare_network_config(hiera_hash('network_scheme', {}))
$cinder_hash            = hiera_hash('cinder', {})
$management_vip         = hiera('management_vip')
$queue_provider         = hiera('queue_provider', 'rabbitmq')
$cinder_volume_group    = hiera('cinder_volume_group', 'cinder')
$storage_hash           = hiera_hash('storage', {})
$ceilometer_hash        = hiera_hash('ceilometer', {})
$sahara_hash            = hiera_hash('sahara', {})
$rabbit_hash            = hiera_hash('rabbit', {})
$service_endpoint       = hiera('service_endpoint')
$workers_max            = hiera('workers_max', 16)
$service_workers        = pick($cinder_hash['workers'], min(max($::processorcount, 2), $workers_max))
$cinder_user_password   = $cinder_hash[user_password]
$keystone_user          = pick($cinder_hash['user'], 'cinder')
$keystone_tenant        = pick($cinder_hash['tenant'], 'services')
$region                 = hiera('region', 'RegionOne')
$ssl_hash               = hiera_hash('use_ssl', {})
$primary_controller     = hiera('primary_controller')
$proxy_port             = hiera('proxy_port', '8080')

$db_type                = 'mysql'
$db_host                = pick($cinder_hash['db_host'], hiera('database_vip'))
$db_user                = pick($cinder_hash['db_user'], 'cinder')
$db_password            = $cinder_hash[db_password]
$db_name                = pick($cinder_hash['db_name'], 'cinder')
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

$keystone_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$keystone_auth_host     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])

$glance_protocol        = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
$glance_endpoint        = get_ssl_property($ssl_hash, {}, 'heat', 'internal', 'hostname', [hiera('glance_endpoint', ''), $management_vip])
$glance_ssl_usage       = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)

$swift_internal_protocol = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
$swift_internal_address  = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$management_vip])

$swift_url = "${swift_internal_protocol}://${swift_internal_address}:${proxy_port}"

if $glance_ssl_usage {
  $glance_api_servers = "${glance_protocol}://${glance_endpoint}:9292"
} else {
  $glance_api_servers = hiera('glance_api_servers', "${management_vip}:9292")
}

$service_port        = '5000'
$auth_uri            = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"
$identity_uri        = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"
# TODO(degorenko): it should be fixed in upstream
$privileged_auth_uri = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/v2.0/"

# Determine who should get the volume service
if roles_include(['cinder']) and $storage_hash['volumes_lvm'] {
  $manage_volumes = 'iscsi'
  $volume_backend_name = $storage_hash['volume_backend_names']['volumes_lvm']
} elsif ($storage_hash['volumes_ceph']) {
  $manage_volumes = 'ceph'
  $volume_backend_name = $storage_hash['volume_backend_names']['volumes_ceph']
} else {
  $volume_backend_name = false
  $manage_volumes = false
}

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

######### Cinder Controller Services ########
class {'openstack::cinder':
  sql_connection           => $db_connection,
  queue_provider           => $queue_provider,
  amqp_hosts               => hiera('amqp_hosts',''),
  amqp_user                => $rabbit_hash['user'],
  amqp_password            => $rabbit_hash['password'],
  rabbit_ha_queues         => true,
  volume_group             => $cinder_volume_group,
  volume_backend_name      => $volume_backend_name,
  physical_volume          => undef,
  manage_volumes           => $manage_volumes,
  enabled                  => true,
  glance_api_servers       => $glance_api_servers,
  bind_host                => get_network_role_property('cinder/api', 'ipaddr'),
  iscsi_bind_host          => get_network_role_property('cinder/iscsi', 'ipaddr'),
  keystone_user            => $keystone_user,
  keystone_tenant          => $keystone_tenant,
  auth_uri                 => $auth_uri,
  privileged_auth_uri      => $privileged_auth_uri,
  region                   => $region,
  identity_uri             => $identity_uri,
  cinder_user_password     => $cinder_user_password,
  use_syslog               => hiera('use_syslog', true),
  use_stderr               => hiera('use_stderr', false),
  primary_controller       => $primary_controller,
  verbose                  => pick($cinder_hash['verbose'], hiera('verbose', true)),
  debug                    => pick($cinder_hash['debug'], hiera('debug', true)),
  default_log_levels       => hiera_hash('default_log_levels'),
  syslog_log_facility      => hiera('syslog_log_facility_cinder', 'LOG_LOCAL3'),
  cinder_rate_limits       => hiera('cinder_rate_limits'),
  max_retries              => $max_retries,
  max_pool_size            => $max_pool_size,
  max_overflow             => $max_overflow,
  idle_timeout             => $idle_timeout,
  notification_driver      => $ceilometer_hash['notification_driver'],
  service_workers          => $service_workers,
  swift_url                => $swift_url,
  cinder_report_interval   => $cinder_hash['cinder_report_interval'],
  cinder_service_down_time => $cinder_hash['cinder_service_down_time'],
} # end class

if $storage_hash['volumes_block_device'] or ($sahara_hash['enabled'] and $storage_hash['volumes_lvm']) {
    $cinder_scheduler_filters = [ 'InstanceLocalityFilter' ]
} else {
    $cinder_scheduler_filters = []
}

class { 'cinder::scheduler::filter':
  scheduler_default_filters => concat($cinder_scheduler_filters, [ 'AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter' ])
}

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'cinder-api':
    package_name => 'cinder-api',
  }
  tweaks::ubuntu_service_override { 'cinder-scheduler':
    package_name => 'cinder-scheduler',
  }
}
