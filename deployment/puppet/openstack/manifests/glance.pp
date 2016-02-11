#
# == Class: openstack::glance
#
# Installs and configures Glance
# Assumes the following:
#   - Keystone for authentication
#   - keystone tenant: services
#   - keystone username: glance
#   - storage backend: file
#
# === Parameters
#
# [*db_connection*]
#   Database connection for glance
#   Defaults to 'mysql://glance:glance@localhost/glance'
#
# [glance_user_password] Password for glance auth user. Required.
# [glance_protocol] Protocol glance used to speak with registry.
#   Optional. Defaults to 'http'
# [auth_uri] URI used for auth. Optional. Defaults to "http://127.0.0.1:5000/"
# [identity_uri] URI used for keyston admin endpoint. Optional. Defaults to "http://127.0.0.1:35357/"
# [verbose] Rather to print more verbose (INFO+) output. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option.
#   Optional. Defaults to false.
# [enabled] Used to indicate if the service should be active (true) or passive (false).
#   Optional. Defaults to true
# [use_syslog] Rather or not service should log to syslog. Optional. Default to false.
# [use_stderr] Rather or not service should send output to stderr. Optional. Defaults to true.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [glance_image_cache_max_size] the maximum size of glance image cache. Optional. Default is 10G.
#
# === Example
#
# class { 'openstack::glance':
#   glance_user_password => 'changeme',
# }

class openstack::glance (
  $db_connection                  = 'mysql://glance:glance@localhost/glance',
  $glance_user                    = 'glance',
  $glance_user_password           = false,
  $glance_tenant                  = 'services',
  $bind_host                      = '127.0.0.1',
  $registry_host                  = '127.0.0.1',
  $auth_uri                       = 'http://127.0.0.1:5000/',
  $identity_uri                   = 'http://127.0.0.1:35357/',
  $region                         = 'RegionOne',
  $glance_protocol                = 'http',
  $glance_backend                 = 'file',
  $glance_vcenter_host            = undef,
  $glance_vcenter_user            = undef,
  $glance_vcenter_password        = undef,
  $glance_vcenter_datacenter      = undef,
  $glance_vcenter_datastore       = undef,
  $glance_vcenter_image_dir       = undef,
  $glance_vcenter_api_retry_count = undef,
  $primary_controller             = false,
  $verbose                        = false,
  $debug                          = false,
  $default_log_levels             = undef,
  $enabled                        = true,
  $use_syslog                     = false,
  $use_stderr                     = true,
  $show_image_direct_url          = true,
  $swift_store_large_object_size  = '5120',
  $pipeline                       = 'keystone',
  # Facility is common for all glance services
  $syslog_log_facility            = 'LOG_LOCAL2',
  $glance_image_cache_max_size    = '10737418240',
  $idle_timeout                   = '3600',
  $max_pool_size                  = '10',
  $max_overflow                   = '30',
  $max_retries                    = '-1',
  $rabbit_password                = false,
  $rabbit_userid                  = 'guest',
  $rabbit_host                    = 'localhost',
  $rabbit_port                    = '5672',
  $rabbit_hosts                   = false,
  $rabbit_virtual_host            = '/',
  $rabbit_use_ssl                 = false,
  $rabbit_notification_exchange   = 'glance',
  $rabbit_notification_topic      = 'notifications',
  $amqp_durable_queues            = false,
  $known_stores                   = false,
  $rbd_store_user                 = 'images',
  $rbd_store_pool                 = 'images',
  $rados_connect_timeout          = '0',
  $notification_driver            = undef,
  $service_workers                = $::processorcount,
) {
  validate_string($glance_user_password)
  validate_string($rabbit_password)

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
    registry_host          => $registry_host,
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

  # puppet-glance assumes rabbit_hosts is an array of [node:port, node:port]
  # but we pass it as a amqp_hosts string of 'node:port, node:port' in Fuel
  if !is_array($rabbit_hosts) {
    $rabbit_hosts_real = split($rabbit_hosts, ',')
    glance_api_config {
      'DEFAULT/kombu_reconnect_delay': value => 5.0;
    }
  } else {
    $rabbit_hosts_real = $rabbit_hosts
  }

  class { 'glance::notify::rabbitmq':
    rabbit_password              => $rabbit_password,
    rabbit_userid                => $rabbit_userid,
    rabbit_hosts                 => $rabbit_hosts_real,
    rabbit_host                  => $rabbit_host,
    rabbit_port                  => $rabbit_port,
    rabbit_virtual_host          => $rabbit_virtual_host,
    rabbit_use_ssl               => $rabbit_use_ssl,
    rabbit_notification_exchange => $rabbit_notification_exchange,
    rabbit_notification_topic    => $rabbit_notification_topic,
    amqp_durable_queues          => $amqp_durable_queues,
    notification_driver          => $notification_driver,
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
        rbd_store_user        => $rbd_store_user,
        rbd_store_pool        => $rbd_store_pool,
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
}
