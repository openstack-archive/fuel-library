class openstack_tasks::openstack_cinder::openstack_cinder {

  notice('MODULAR: openstack_cinder/openstack_cinder.pp')

  #Network stuff
  prepare_network_config(hiera_hash('network_scheme', {}))
  $cinder_hash            = hiera_hash('cinder', {})
  $management_vip         = hiera('management_vip')
  $volume_group           = hiera('cinder_volume_group', 'cinder')
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
  $kombu_compression      = hiera('kombu_compression', $::os_service_default)

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

  $queue_provider = hiera('queue_provider', 'rabbit')

  $keystone_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $keystone_auth_host     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])

  # get glance api servers list
  $glance_endpoint_default = hiera('glance_endpoint', $management_vip)
  $glance_protocol         = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_endpoint         = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', $glance_endpoint_default)
  $glance_api_servers      = hiera('glance_api_servers', "${glance_protocol}://${glance_endpoint}:9292")

  $swift_internal_protocol = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
  $swift_internal_address  = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$management_vip])

  $swift_url = "${swift_internal_protocol}://${swift_internal_address}:${proxy_port}"

  $service_port        = '5000'
  $keystone_api        = hiera('keystone_api', 'v3')
  $auth_uri            = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"
  $identity_uri        = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"
  # TODO(degorenko): it should be fixed in upstream
  $privileged_auth_uri = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/${keystone_api}/"

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

  $bind_host       = get_network_role_property('cinder/api', 'ipaddr')
  $iscsi_bind_host = get_network_role_property('cinder/iscsi', 'ipaddr')
  $use_syslog      = hiera('use_syslog', true)
  $use_stderr      = hiera('use_stderr', false)
  $verbose         = pick($cinder_hash['verbose'], hiera('verbose', true))
  $debug           = pick($cinder_hash['debug'], hiera('debug', true))

  ######### Cinder Controller Services ########
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

  include cinder::params

  class {'cinder::glance':
    glance_api_servers => $glance_api_servers,
    # Glance API v2 is required for Ceph RBD backend
    glance_api_version => '2',
  }

  #NOTE(mattymo): Remove keymgr_encryption_auth_url after LP#1516085 is fixed
  $keymgr_encryption_auth_url = "${identity_uri}/v3"

  class { '::cinder':
    rpc_backend              => $queue_provider,
    rabbit_hosts             => split(hiera('amqp_hosts',''), ','),
    rabbit_userid            => $rabbit_hash['user'],
    rabbit_password          => $rabbit_hash['password'],
    database_connection      => $db_connection,
    verbose                  => $verbose,
    use_syslog               => $use_syslog,
    use_stderr               => $use_stderr,
    log_facility             => hiera('syslog_log_facility_cinder', 'LOG_LOCAL3'),
    debug                    => $debug,
    database_idle_timeout    => $idle_timeout,
    database_max_pool_size   => $max_pool_size,
    database_max_retries     => $max_retries,
    database_max_overflow    => $max_overflow,
    control_exchange         => 'cinder',
    rabbit_ha_queues         => true,
    report_interval          => $cinder_hash['cinder_report_interval'],
    service_down_time        => $cinder_hash['cinder_service_down_time'],
    kombu_compression        => $kombu_compression,
  }

  if ($bind_host) {
    class { 'cinder::api':
      auth_uri                     => $auth_uri,
      identity_uri                 => $identity_uri,
      keystone_user                => $keystone_user,
      keystone_tenant              => $keystone_tenant,
      keystone_password            => $cinder_user_password,
      os_region_name               => $region,
      bind_host                    => $bind_host,
      ratelimits                   => hiera('cinder_rate_limits'),
      service_workers              => $service_workers,
      privileged_user              => true,
      os_privileged_user_password  => $cinder_user_password,
      os_privileged_user_tenant    => $keystone_tenant,
      os_privileged_user_auth_url  => $privileged_auth_uri,
      os_privileged_user_name      => $keystone_user,
      keymgr_encryption_auth_url   => $keymgr_encryption_auth_url,
      nova_catalog_admin_info      => 'compute:nova:adminURL',
      nova_catalog_info            => 'compute:nova:internalURL',
      sync_db                      => $primary_controller,
    }

    class { 'cinder::scheduler': }

    # Note, because keystone is enabled
    cinder_config {
      'keystone_authtoken/signing_dir':     value => '/tmp/keystone-signing-cinder';
      'keystone_authtoken/signing_dirname': value => '/tmp/keystone-signing-cinder';
      'keystone_authtoken/auth_version':    value => $keystone_api;
    }
  }

  if $manage_volumes {
    ####### Disable upstart startup on install #######
    #NOTE(bogdando) ceph::backends::rbd creates override file as well
    if($::operatingsystem == 'Ubuntu' and $manage_volumes != 'ceph') {
      tweaks::ubuntu_service_override { 'cinder-volume':
        package_name => 'cinder-volume',
      }
    }

    if($::operatingsystem == 'Ubuntu' and $manage_volumes == 'ceph') {
      tweaks::ubuntu_service_override { 'tgtd-service':
        package_name => $::cinder::params::tgt_package_name,
        service_name => $::cinder::params::tgt_service_name,
      }
      package { $::cinder::params::tgt_package_name:
        ensure => installed,
        name   => $::cinder::params::tgt_package_name,
        before => Class['cinder::volume'],
      }
      service { "$::cinder::params::tgt_service_name":
        ensure => stopped,
        enable => false,
      }
    }

    class { 'cinder::volume': }

    # TODO(xarses): figure out if this is used anymore, it was a param, but
    # we don't set it, and it's only used my mlnx
    $iser = false

    # TODO(xarses) figure out if these are still used too
    $rbd_pool               = 'volumes'
    $rbd_user               = 'volumes'
    $rbd_secret_uuid        = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455'


    case $manage_volumes {
      true, 'iscsi': {
        cinder::backend::iscsi { 'DEFAULT':
          iscsi_ip_address    => $iscsi_bind_host,
          volume_group        => $volume_group,
          volume_backend_name => $volume_backend_name,
        }

        class { 'cinder::backup': }

        tweaks::ubuntu_service_override { 'cinder-backup':
          package_name => 'cinder-backup',
        }

        class { 'cinder::backup::swift':
          backup_swift_url      => "${swift_url}/v1/AUTH_",
          backup_swift_auth_url => "${auth_uri}/v2.0",
        }
      }
      'ceph': {
        if defined(Class['::ceph']) {
          Ceph::Pool<| title == $::ceph::cinder_pool |> ->
          Cinder::Backend::Rbd['DEFAULT']
        }

        cinder::backend::rbd { 'DEFAULT':
          rbd_pool            => $rbd_pool,
          rbd_user            => $rbd_user,
          rbd_secret_uuid     => $rbd_secret_uuid,
          volume_backend_name => $volume_backend_name,
        }

        class { 'cinder::backup': }

        tweaks::ubuntu_service_override { 'cinder-backup':
          package_name => 'cinder-backup',
        }

        class { 'cinder::backup::ceph':
          backup_ceph_user => 'backups',
          backup_ceph_pool => 'backups',
        }
      }
    }
  }

  if $use_syslog {
    cinder_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  if $ceilometer_hash['enabled'] {
    class { 'cinder::ceilometer':
      notification_driver => $ceilometer_hash['notification_driver']
    }
  }
}
