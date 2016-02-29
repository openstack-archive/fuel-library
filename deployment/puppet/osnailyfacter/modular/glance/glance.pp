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
$ceilometer_hash       = hiera_hash('ceilometer_hash', {})
$region                = hiera('region','RegionOne')
$workers_max           = hiera('workers_max', 16)
$service_workers       = pick($glance_hash['glance_workers'],
                              min(max($::processorcount, 2), $workers_max))
$ironic_hash           = hiera_hash('ironic', {})
$primary_controller    = hiera('primary_controller')

$db_type      = 'mysql'
$db_host      = pick($glance_hash['db_host'], $database_vip)
$db_user      = pick($glance_hash['db_user'], 'glance')
$db_password  = $glance_hash['db_password']
$db_name      = pick($glance_hash['db_name'], 'glance')
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

$bind_host                      = get_network_role_property('glance/api', 'ipaddr')
$enabled                        = true
$max_retries                    = '-1'
$idle_timeout                   = '3600'

$rabbit_password                = $rabbit_hash['password']
$rabbit_userid                  = $rabbit_hash['user']
$rabbit_hosts                   = split(hiera('amqp_hosts',''), ',')

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
$pipeline                       = pick($glance_hash['pipeline'], 'keystone')
$glance_large_object_size       = pick($glance_hash['large_object_size'], '5120')

$ssl_hash               = hiera_hash('use_ssl', {})
$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('service_endpoint', ''), $management_vip])
$admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('service_endpoint', ''), $management_vip])
$glance_endpoint        = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])

$auth_uri     = "${internal_auth_protocol}://${internal_auth_address}:5000/"
$identity_uri = "${admin_auth_protocol}://${admin_auth_address}:35357/"

$rados_connect_timeout          = '30'

if ($storage_hash['images_ceph'] and !$ironic_hash['enabled']) {
  $glance_backend = 'ceph'
  $known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
  $show_image_direct_url = pick($glance_hash['show_image_direct_url'], true)
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
  $show_image_direct_url = pick($glance_hash['show_image_direct_url'], true)
} else {
  $glance_backend = 'swift'
  $known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
  $swift_store_large_object_size = $glance_large_object_size
  $show_image_direct_url = pick($glance_hash['show_image_direct_url'], false)
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


# Install and configure glance-api
class { 'glance::api':
  verbose                => $verbose,
  debug                  => $debug,
  bind_host              => $bind_host,
  auth_type              => 'keystone',
  auth_uri               => $auth_uri,
  identity_uri           => $identity_uri,
  keystone_user          => $glance_user,
  keystone_password      => $glance_user_password,
  keystone_tenant        => $glance_tenant,
  database_connection    => $db_connection,
  enabled                => $enabled,
  workers                => $service_workers,
  registry_host          => $glance_endpoint,
  use_syslog             => $use_syslog,
  use_stderr             => $use_stderr,
  log_facility           => $syslog_log_facility,
  database_idle_timeout  => $idle_timeout,
  database_max_pool_size => $max_pool_size,
  database_max_retries   => $max_retries,
  database_max_overflow  => $max_overflow,
  show_image_direct_url  => $show_image_direct_url,
  pipeline               => $pipeline,
  known_stores           => $known_stores,
  os_region_name         => $region,
  delayed_delete         => false,
  scrub_time             => '43200',
  auth_region            => $region,
  signing_dir            => '/tmp/keystone-signing-glance',
  token_cache_time       => '-1',
  image_cache_stall_time => '86400',
  image_cache_max_size   => $glance_image_cache_max_size,
}

glance_api_config {
  'DEFAULT/scrubber_datadir': value => '/var/lib/glance/scrubber';
}


# TODO (iberezovskiy): use glance::cache::logging class to setup
# these parameters after new sync for glance module
# (https://review.openstack.org/#/c/238096/)
glance_cache_config {
  'DEFAULT/image_cache_dir':  value => '/var/lib/glance/image-cache/';
  'DEFAULT/os_region_name':   value => $region;
}

# Install and configure glance-registry
class { 'glance::registry':
  verbose                => $verbose,
  debug                  => $debug,
  bind_host              => $bind_host,
  auth_uri               => $auth_uri,
  identity_uri           => $identity_uri,
  auth_type              => 'keystone',
  keystone_user          => $glance_user,
  keystone_password      => $glance_user_password,
  keystone_tenant        => $glance_tenant,
  database_connection    => $db_connection,
  database_max_pool_size => $max_pool_size,
  database_max_retries   => $max_retries,
  database_max_overflow  => $max_overflow,
  enabled                => $enabled,
  use_syslog             => $use_syslog,
  use_stderr             => $use_stderr,
  log_facility           => $syslog_log_facility,
  database_idle_timeout  => $idle_timeout,
  workers                => $service_workers,
  sync_db                => $primary_controller,
  signing_dir            => '/tmp/keystone-signing-glance',
  os_region_name         => $region,
}

class { 'glance::notify::rabbitmq':
  rabbit_password              => $rabbit_password,
  rabbit_userid                => $rabbit_userid,
  rabbit_hosts                 => $split($rabbit_hosts, ','),
  kombu_reconnect_delay        => 5.0,
  notification_driver          => $ceilometer_hash['notification_driver'],
}

# syslog additional settings default/use_syslog_rfc_format = true
if $use_syslog {
  glance_api_config {
    'DEFAULT/use_syslog_rfc_format': value => true;
  }
  glance_cache_config {
    'DEFAULT/use_syslog_rfc_format': value => true;
  }
  glance_registry_config {
    'DEFAULT/use_syslog_rfc_format': value => true;
  }
}

# Configure file storage backend
case $glance_backend {
  'swift': {
    if !defined(Package['swift']) {
      include ::swift::params
      package { 'swift':
        ensure => present,
        name   => $::swift::params::package_name,
      }
    }
    Package['swift'] ~> Service['glance-api']
    Package['swift'] -> Swift::Ringsync <||>
    Package<| title == 'swift'|> ~> Service<| title == 'glance-api'|>
    if !defined(Service['glance-api']) {
      notify{ "Module ${module_name} cannot notify service glance-api on package swift update": }
    }
    class { 'glance::backend::swift':
      swift_store_user                    => "${glance_tenant}:${glance_user}",
      swift_store_key                     => $glance_user_password,
      swift_store_create_container_on_put => 'True',
      swift_store_large_object_size       => $swift_store_large_object_size,
      swift_store_auth_address            => "${auth_uri}/v2.0/",
      swift_store_region                  => $region,
    }
  }
  'rbd', 'ceph': {
    Ceph::Pool<| title == $::ceph::glance_pool |> ->
    class { 'glance::backend::rbd':
      rbd_store_user        => 'images',
      rbd_store_pool        => 'images',
      rados_connect_timeout => $rados_connect_timeout,
    }
  }
  'vmware': {
    class { 'glance::backend::vsphere':
        vcenter_host            => $glance_vcenter_host,
        vcenter_user            => $glance_vcenter_user,
        vcenter_password        => $glance_vcenter_password,
        vcenter_datacenter      => $glance_vcenter_datacenter,
        vcenter_datastore       => $glance_vcenter_datastore,
        vcenter_image_dir       => $glance_vcenter_image_dir,
        vcenter_api_retry_count => $glance_vcenter_api_retry_count
    }
  }
  default: {
    class { "glance::backend::${glance_backend}": }
  }
}

# Configure cache pruner and cache cleaner
Class['glance::api'] ->
class { 'glance::cache::pruner': } ->
class { 'glance::cache::cleaner': }
