notice('MODULAR: glance.pp')

$verbose               = hiera('verbose', true)
$debug                 = hiera('debug', false)
$management_vip        = hiera('management_vip')
$glance_hash           = hiera('glance')
$storage_hash          = hiera('storage')
$internal_address      = hiera('internal_address')
$use_syslog            = hiera('use_syslog', true)
$use_stderr            = hiera('use_stderr', false)
$syslog_log_facility   = hiera('syslog_log_facility_glance')
$rabbit_hash           = hiera('rabbit_hash')
$amqp_hosts            = hiera('amqp_hosts')
$max_pool_size         = hiera('max_pool_size')
$max_overflow          = hiera('max_overflow')
$ceilometer_hash       = hiera('ceilometer',{})

$db_type                        = 'mysql'
$db_host                        = $management_vip
$service_endpoint               = $management_vip
$api_bind_address               = $internal_address
$enabled                        = true
$max_retries                    = '-1'
$idle_timeout                   = '3600'
$auth_uri                       = "http://${service_endpoint}:5000/"

$rabbit_password                = $rabbit_hash['password']
$rabbit_user                    = $rabbit_hash['user']
$rabbit_hosts                   = split($amqp_hosts, ',')
$rabbit_virtual_host            = '/'

$glance_db_user                 = 'glance'
$glance_db_dbname               = 'glance'
$glance_db_password             = $glance_hash['db_password']
$glance_user_password           = $glance_hash['user_password']
$glance_vcenter_host            = $glance_hash['vc_host']
$glance_vcenter_user            = $glance_hash['vc_user']
$glance_vcenter_password        = $glance_hash['vc_password']
$glance_vcenter_datacenter      = $glance_hash['vc_datacenter']
$glance_vcenter_datastore       = $glance_hash['vc_datastore']
$glance_vcenter_image_dir       = $glance_hash['vc_image_dir']
$glance_vcenter_api_retry_count = '20'
$glance_image_cache_max_size    = $glance_hash['image_cache_max_size']

if ($storage_hash['images_ceph']) {
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
  $glance_show_image_direct_url = pick($glance_hash['show_image_direct_url'], false)
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
  glance_user_password           => $glance_user_password,
  glance_vcenter_host            => $glance_vcenter_host,
  glance_vcenter_user            => $glance_vcenter_user,
  glance_vcenter_password        => $glance_vcenter_password,
  glance_vcenter_datacenter      => $glance_vcenter_datacenter,
  glance_vcenter_datastore       => $glance_vcenter_datastore,
  glance_vcenter_image_dir       => $glance_vcenter_image_dir,
  glance_vcenter_api_retry_count => $glance_vcenter_api_retry_count,
  auth_uri                       => $auth_uri,
  keystone_host                  => $service_endpoint,
  bind_host                      => $api_bind_address,
  enabled                        => $enabled,
  glance_backend                 => $glance_backend,
  registry_host                  => $service_endpoint,
  use_syslog                     => $use_syslog,
  use_stderr                     => $use_stderr,
  show_image_direct_url          => $glance_show_image_direct_url,
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
 }

glance_api_config {
  'keystone_authtoken/token_cache_time': value => '-1';
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
