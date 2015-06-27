notice('MODULAR: glance.pp')

$verbose               = hiera('verbose', true)
$debug                 = hiera('debug', false)
$management_vip        = hiera('management_vip')
$internal_ssl_hash     = hiera('internal_ssl')
$service_endpoint      = hiera('service_endpoint', $internal_ssl_hash['enable'] ? {
  true    => $internal_ssl_hash['hostname'],
  default => $management_vip,
})
$glance_hash           = hiera_hash('glance', {})
$storage_hash          = hiera('storage')
$internal_address      = hiera('internal_address')
$use_syslog            = hiera('use_syslog', true)
$syslog_log_facility   = hiera('syslog_log_facility_glance')
$rabbit_hash           = hiera_hash('rabbit_hash', {})
$amqp_hosts            = hiera('amqp_hosts')
$max_pool_size         = hiera('max_pool_size')
$max_overflow          = hiera('max_overflow')
$ceilometer_hash       = hiera_hash('ceilometer', {})
$keystone_endpoint     = hiera('keystone_endpoint', $service_endpoint)
$glance_endpoint       = hiera('glance_endpoint', $service_endpoint)

$db_type                        = 'mysql'
$db_host                        = pick($glance_hash['db_host'], $management_vip)
$api_bind_address               = $internal_address
$enabled                        = true
$max_retries                    = '-1'
$idle_timeout                   = '3600'
$auth_uri                       = $internal_ssl_hash['enable'] ? {
  true    => "https://${keystone_endpoint}:5000/",
  default => "http://${keystone_endpoint}:5000/",
}

$rabbit_password                = $rabbit_hash['password']
$rabbit_user                    = $rabbit_hash['user']
$rabbit_hosts                   = split($amqp_hosts, ',')
$rabbit_virtual_host            = '/'

$glance_db_user                 = pick($glance_hash['db_user'], 'glance')
$glance_db_dbname               = pick($glance_hash['db_name'], 'glance')
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
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
} else {
  $glance_backend = 'swift'
  $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
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
  internal_ssl                   => $internal_ssl_hash['enable'],
  keystone_host                  => $internal_ssl_hash['enable'] ? {
    true    => $internal_ssl_hash['hostname'],
    default => $service_endpoint,
  },
  bind_host                      => $api_bind_address,
  enabled                        => $enabled,
  glance_backend                 => $glance_backend,
  registry_host                  => $glance_endpoint,
  use_syslog                     => $use_syslog,
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
