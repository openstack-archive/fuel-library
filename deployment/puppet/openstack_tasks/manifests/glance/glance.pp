class openstack_tasks::glance::glance {

  notice('MODULAR: glance/glance.pp')

  $network_scheme   = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $glance_hash         = hiera_hash('glance', {})
  $glance_glare_hash   = hiera_hash('glance_glare', {})
  $debug               = pick($glance_hash['debug'], hiera('debug', false))
  $management_vip      = hiera('management_vip')
  $database_vip        = hiera('database_vip')
  $service_endpoint    = hiera('service_endpoint')
  $storage_hash        = hiera('storage')
  $use_syslog          = hiera('use_syslog', true)
  $use_stderr          = hiera('use_stderr', false)
  $syslog_log_facility = hiera('syslog_log_facility_glance')
  $rabbit_hash         = hiera_hash('rabbit', {})
  $max_pool_size       = hiera('max_pool_size')
  $max_overflow        = hiera('max_overflow')
  $ceilometer_hash     = hiera_hash('ceilometer', {})
  $region              = hiera('region','RegionOne')
  $workers_max         = hiera('workers_max', $::os_workers)
  $service_workers     = pick($glance_hash['glance_workers'],
                              min(max($::processorcount, 2), $workers_max))
  $ironic_hash         = hiera_hash('ironic', {})
  $primary_controller  = hiera('primary_controller')
  $kombu_compression   = hiera('kombu_compression', $::os_service_default)
  $memcached_servers   = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  $rabbit_heartbeat_timeout_threshold = pick($glance_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($glance_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

  $db_type     = pick($glance_hash['db_type'], 'mysql+pymysql')
  $db_host     = pick($glance_hash['db_host'], $database_vip)
  $db_user     = pick($glance_hash['db_user'], 'glance')
  $db_password = $glance_hash['db_password']
  $db_name     = pick($glance_hash['db_name'], 'glance')
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

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

  $api_bind_host                  = get_network_role_property('glance/api', 'ipaddr')
  $glare_bind_host                = get_network_role_property('glance/glare', 'ipaddr')
  $enabled                        = true
  $max_retries                    = '-1'
  $idle_timeout                   = '3600'

  $glance_user                    = pick($glance_hash['user'],'glance')
  $glance_user_password           = $glance_hash['user_password']
  $glance_tenant                  = pick($glance_hash['tenant'],'services')
  $glance_glare_user              = pick($glance_glare_hash['user'],'glare')
  $glance_glare_user_password     = $glance_glare_hash['user_password']
  $glance_glare_tenant            = pick($glance_glare_hash['tenant'],'services')
  $glance_image_cache_max_size    = $glance_hash['image_cache_max_size']
  $pipeline                       = pick($glance_hash['pipeline'], 'keystone')
  $glance_large_object_size       = pick($glance_hash['large_object_size'], '5120')

  $ssl_hash               = hiera_hash('use_ssl', {})
  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('service_endpoint', ''), $management_vip])
  $admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('service_endpoint', ''), $management_vip])
  $glance_endpoint        = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])

  $auth_uri = "${internal_auth_protocol}://${internal_auth_address}:5000/"
  $auth_url = "${admin_auth_protocol}://${admin_auth_address}:35357/"

  $rados_connect_timeout = '30'

  if ($storage_hash['images_ceph'] and !$ironic_hash['enabled']) {
    $glance_backend = 'ceph'
    $known_stores   = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
    $show_multiple_locations = pick($glance_hash['show_multiple_locations'], true)
    $show_image_direct_url = pick($glance_hash['show_image_direct_url'], true)
  } else {
    $glance_backend = 'swift'
    $known_stores   = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
    $swift_store_large_object_size = $glance_large_object_size
    $show_multiple_locations = pick($glance_hash['show_multiple_locations'], false)
    $show_image_direct_url = pick($glance_hash['show_image_direct_url'], false)
  }

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'glance-api':
      package_name => 'glance-api',
    }
    tweaks::ubuntu_service_override { 'glance-glare':
      package_name => 'glance-glare',
    }
    tweaks::ubuntu_service_override { 'glance-registry':
      package_name => 'glance-registry',
    }
  }

  class { '::glance::api::authtoken':
    username          => $glance_user,
    password          => $glance_user_password,
    project_name      => $glance_tenant,
    auth_url          => $auth_url,
    auth_uri          => $auth_uri,
    token_cache_time  => '300',
    memcached_servers => $local_memcached_server,
  }

  # Install and configure glance-api
  class { '::glance::api':
    debug                   => $debug,
    bind_host               => $api_bind_host,
    auth_strategy           => 'keystone',
    database_connection     => $db_connection,
    enabled                 => $enabled,
    workers                 => $service_workers,
    registry_host           => $glance_endpoint,
    use_syslog              => $use_syslog,
    use_stderr              => $use_stderr,
    log_facility            => $syslog_log_facility,
    database_idle_timeout   => $idle_timeout,
    database_max_pool_size  => $max_pool_size,
    database_max_retries    => $max_retries,
    database_max_overflow   => $max_overflow,
    show_image_direct_url   => $show_image_direct_url,
    show_multiple_locations => $show_multiple_locations,
    pipeline                => $pipeline,
    stores                  => $known_stores,
    os_region_name          => $region,
    delayed_delete          => false,
    scrub_time              => '43200',
    image_cache_stall_time  => '86400',
    image_cache_max_size    => $glance_image_cache_max_size,
  }

  class { '::glance::glare::logging':
    use_syslog         => $use_syslog,
    use_stderr         => $use_stderr,
    log_facility       => $syslog_log_facility,
    debug              => $debug,
    default_log_levels => hiera('default_log_levels'),
  }

  class { '::glance::glare::db':
    database_connection    => $db_connection,
    database_idle_timeout  => $idle_timeout,
    database_max_pool_size => $max_pool_size,
    database_max_retries   => $max_retries,
    database_max_overflow  => $max_overflow,
  }

  class { '::glance::glare::authtoken':
    username          => $glance_glare_user,
    password          => $glance_glare_user_password,
    project_name      => $glance_glare_tenant,
    auth_url          => $auth_url,
    auth_uri          => $auth_uri,
    token_cache_time  => '300',
    memcached_servers => $local_memcached_server,
  }

  class { '::glance::glare':
    bind_host         => $glare_bind_host,
    auth_strategy     => 'keystone',
    enabled           => $enabled,
    stores            => $known_stores,
    workers           => $service_workers,
    pipeline          => $pipeline,
    os_region_name    => $region,
  }

  glance_api_config {
    'DEFAULT/scrubber_datadir': value => '/var/lib/glance/scrubber';
  }

  glance_cache_config {
    'DEFAULT/image_cache_dir':  value => '/var/lib/glance/image-cache/';
    'DEFAULT/os_region_name':   value => $region;
  }

  class { '::glance::registry::authtoken':
    username          => $glance_user,
    password          => $glance_user_password,
    project_name      => $glance_tenant,
    auth_url          => $auth_url,
    auth_uri          => $auth_uri,
    memcached_servers => $local_memcached_server,
  }

  # Install and configure glance-registry
  class { '::glance::registry':
    debug                  => $debug,
    bind_host              => $api_bind_host,
    auth_strategy          => 'keystone',
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
    os_region_name         => $region,
  }

  class { '::glance::notify::rabbitmq':
    rabbit_notification_exchange       => 'glance',
    rabbit_notification_topic          => 'notifications',
    default_transport_url              => $transport_url,
    notification_driver                => $ceilometer_hash['notification_driver'],
    kombu_compression                  => $kombu_compression,
    rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
    rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,
  }

  # syslog additional settings default/use_syslog_rfc_format = true
  if $use_syslog {
    glance_api_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
    glance_glare_config {
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
      class { '::glance::backend::swift':
        swift_store_user                    => "${glance_tenant}:${glance_user}",
        swift_store_key                     => $glance_user_password,
        swift_store_create_container_on_put => 'True',
        swift_store_large_object_size       => $swift_store_large_object_size,
        swift_store_auth_address            => "${auth_uri}/v3",
        swift_store_auth_version            => '3',
        swift_store_region                  => $region,
        glare_enabled                       => true,
      }
    }
    'rbd', 'ceph': {
      Ceph::Pool<| title == $::ceph::glance_pool |> ->
      class { '::glance::backend::rbd':
        rbd_store_user        => 'images',
        rbd_store_pool        => 'images',
        rados_connect_timeout => $rados_connect_timeout,
        glare_enabled         => true,
      }
    }
    default: {
      class { "glance::backend::${glance_backend}":
        glare_enabled => true,
      }
    }
  }

  # Configure cache pruner and cache cleaner
  Class['::glance::api'] ->
  class { '::glance::cache::pruner': } ->
  class { '::glance::cache::cleaner': }
}
