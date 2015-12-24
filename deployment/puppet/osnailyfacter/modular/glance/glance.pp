notice('MODULAR: glance.pp')

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$glance_hash           = hiera_hash('glance', {})
$verbose               = pick($glance_hash['verbose'], hiera('verbose', true))
$debug                 = pick($glance_hash['debug'], hiera('debug', false))
$management_vip        = hiera('management_vip')
$database_vip          = hiera('database_vip')
$service_endpoint      = hiera('service_endpoint')
$storage_hash          = hiera('storage')
$use_syslog            = hiera('use_syslog', true)
$use_stderr            = hiera('use_stderr', false)
$syslog_log_facility   = hiera('syslog_log_facility_glance')
$rabbit_hash           = hiera_hash('rabbit_hash', {})
$max_pool_size         = hiera('max_pool_size')
$max_overflow          = hiera('max_overflow')
$ceilometer_hash       = hiera_hash('ceilometer', {})
$region                = hiera('region','RegionOne')
$service_workers       = pick($glance_hash['glance_workers'], min(max($::processorcount, 2), 16))
$ironic_hash           = hiera_hash('ironic', {})
$primary_controller    = hiera('primary_controller')

$default_log_levels             = hiera_hash('default_log_levels')

$db_type      = 'mysql'
$db_host      = pick($glance_hash['db_host'], $database_vip)
$db_user      = pick($glance_hash['db_user'], 'glance')
$db_password  = $glance_hash['db_password']
$db_name      = pick($glance_hash['db_name'], 'glance')
# LP#1526938 - python-mysqldb supports this, python-pymysql does not
if $::os_package_type == 'debian' {
  $extra_params = 'read_timeout=60'
} else {
  $extra_params = ''
}
$db_connection = db_connection_string($db_host, $db_user, $db_password,
                                      $db_name, $db_type, $extra_params)

$api_bind_address               = get_network_role_property('glance/api', 'ipaddr')
$enabled                        = true
$max_retries                    = '-1'
$idle_timeout                   = '3600'

$rabbit_password                = $rabbit_hash['password']
$rabbit_user                    = $rabbit_hash['user']
$rabbit_hosts                   = split(hiera('amqp_hosts',''), ',')
$rabbit_virtual_host            = '/'

$glance_user                    = pick($glance_hash['user'],'glance')
$glance_user_password           = $glance_hash['user_password']
$glance_tenant                  = pick($glance_hash['tenant'],'services')
$glance_vcenter_host            = $glance_hash['vc_host']
$glance_vcenter_user            = $glance_hash['vc_user']
$glance_vcenter_password        = $glance_hash['vc_password']
$glance_vcenter_datacenter      = $glance_hash['vc_datacenter']
$glance_vcenter_datastore       = $glance_hash['vc_datastore']
$glance_vcenter_image_dir       = $glance_hash['vc_image_dir']
$glance_vcenter_api_retry_count = '20'
$glance_image_cache_max_size    = $glance_hash['image_cache_max_size']
$glance_pipeline                = pick($glance_hash['pipeline'], 'keystone')
$glance_large_object_size       = pick($glance_hash['large_object_size'], '5120')

$ssl_hash                       = hiera_hash('use_ssl', {})
$keystone_protocol              = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_ssl                   = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'usage', false)
$keystone_endpoint              = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('service_endpoint', ''), $management_vip])
$glance_endpoint                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])

$auth_uri          = "${keystone_protocol}://${keystone_endpoint}:5000/"

$rados_connect_timeout          = '30'

if ($storage_hash['images_ceph'] and !$ironic_hash['enabled']) {
  $glance_backend = 'ceph'
  $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
  $glance_show_image_direct_url = pick($glance_hash['show_image_direct_url'], true)
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
  $glance_show_image_direct_url = pick($glance_hash['show_image_direct_url'], true)
} else {
  $glance_backend = 'swift'
  $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
  $swift_store_large_object_size = $glance_large_object_size
  $glance_show_image_direct_url = pick($glance_hash['show_image_direct_url'], false)
}

###############################################################################

class { 'openstack::glance':
  verbose                        => $verbose,
  debug                          => $debug,
  default_log_levels             => $default_log_levels,
  db_connection                  => $db_connection,
  glance_user                    => $glance_user,
  glance_user_password           => $glance_user_password,
  glance_tenant                  => $glance_tenant,
  glance_vcenter_host            => $glance_vcenter_host,
  glance_vcenter_user            => $glance_vcenter_user,
  glance_vcenter_password        => $glance_vcenter_password,
  glance_vcenter_datacenter      => $glance_vcenter_datacenter,
  glance_vcenter_datastore       => $glance_vcenter_datastore,
  glance_vcenter_image_dir       => $glance_vcenter_image_dir,
  glance_vcenter_api_retry_count => $glance_vcenter_api_retry_count,
  auth_uri                       => $auth_uri,
  keystone_host                  => $keystone_endpoint,
  internal_ssl                   => $internal_ssl,
  glance_protocol                => 'http',
  region                         => $region,
  bind_host                      => $api_bind_address,
  primary_controller             => $primary_controller,
  enabled                        => $enabled,
  glance_backend                 => $glance_backend,
  registry_host                  => $glance_endpoint,
  use_syslog                     => $use_syslog,
  use_stderr                     => $use_stderr,
  show_image_direct_url          => $glance_show_image_direct_url,
  swift_store_large_object_size  => $swift_store_large_object_size,
  pipeline                       => $glance_pipeline,
  syslog_log_facility            => $syslog_log_facility,
  glance_image_cache_max_size    => $glance_image_cache_max_size,
  max_retries                    => $max_retries,
  max_pool_size                  => $max_pool_size,
  max_overflow                   => $max_overflow,
  idle_timeout                   => $idle_timeout,
  rabbit_password                => $rabbit_password,
  rabbit_userid                  => $rabbit_user,
  rabbit_hosts                   => $rabbit_hosts,
  rabbit_virtual_host            => $rabbit_virtual_host,
  known_stores                   => $glance_known_stores,
  ceilometer                     => $ceilometer_hash[enabled],
  service_workers                => $service_workers,
  rados_connect_timeout          => $rados_connect_timeout,
}

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'glance-api':
    package_name => 'glance-api',
  }
  tweaks::ubuntu_service_override { 'glance-registry':
    package_name => 'glance-registry',
  }
}
