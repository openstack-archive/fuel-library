notice('MODULAR: glance.pp')

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$verbose               = hiera('verbose', true)
$debug                 = hiera('debug', false)
$management_vip        = hiera('management_vip')
$database_vip          = hiera('database_vip')
$service_endpoint      = hiera('service_endpoint')
$glance_hash           = hiera_hash('glance', {})
$storage_hash          = hiera_hash('storage', {})
$use_syslog            = hiera('use_syslog', true)
$syslog_log_facility   = hiera('syslog_log_facility_glance')
$rabbit_hash           = hiera_hash('rabbit', {})
$ceilometer_hash       = hiera_hash('ceilometer', {})
$region                = hiera('region','RegionOne')
$glance_endpoint       = $management_vip

$sql_alchemy_hash      = hiera_hash('sql_alchemy', {})
$max_pool_size         = pick($sql_alchemy_hash['max_pool_size'], '20')
$max_overflow          = pick($sql_alchemy_hash['max_overflow'], '20')
$max_retries           = pick($sql_alchemy_hash['max_retries'], '-1')
$idle_timeout          = pick($sql_alchemy_hash['idle_timeout'], '3600')

$db_type                        = 'mysql'
$db_host                        = pick($glance_hash['db_host'], $database_vip)
$api_bind_address               = get_network_role_property('glance/api', 'ipaddr')
$enabled                        = true
$auth_uri                       = "http://${service_endpoint}:5000/"

$rabbit_password                = $rabbit_hash['password']
$rabbit_user                    = pick($rabbit_hash['user'], 'nova')
$rabbit_hosts                   = split(hiera('amqp_hosts',''), ',')
$rabbit_virtual_host            = '/'

$glance_db_user                 = pick($glance_hash['db_user'], 'glance')
$glance_db_dbname               = pick($glance_hash['db_name'], 'glance')
$glance_db_password             = $glance_hash['db_password']
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
$glance_show_image_direct_url   = pick($glance_hash['show_image_direct_url'], true)
$glance_pipeline                = pick($glance_hash['pipeline'], 'keystone')
$glance_large_object_size       = pick($glance_hash['large_object_size'], '5120')

if ($storage_hash['images_ceph']) {
  $glance_backend = 'ceph'
  $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
} else {
  $glance_backend = 'swift'
  $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
  $swift_store_large_object_size = $glance_large_object_size
}

###############################################################################

class { 'openstack::glance':
  verbose                        => $verbose,
  debug                          => $debug,
  db_type                        => $db_type,
  db_host                        => $db_host,
  glance_db_user                 => $glance_db_user,
  glance_db_dbname               => $glance_db_dbname,
  glance_db_password             => $glance_db_password,
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
  keystone_host                  => $service_endpoint,
  region                         => $region,
  bind_host                      => $api_bind_address,
  enabled                        => $enabled,
  glance_backend                 => $glance_backend,
  registry_host                  => $glance_endpoint,
  use_syslog                     => $use_syslog,
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
  ceilometer                     => $ceilometer_hash['enabled'],
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
