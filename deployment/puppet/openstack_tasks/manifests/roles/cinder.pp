class openstack_tasks::roles::cinder {

  notice('MODULAR: roles/cinder.pp')

  # Pulling hiera
  $network_scheme   = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $cinder_hash                = hiera_hash('cinder', {})
  $volume_group               = hiera('cinder_volume_group', 'cinder')
  $iscsi_bind_host            = get_network_role_property('cinder/iscsi', 'ipaddr')
  $public_vip                 = hiera('public_vip')
  $management_vip             = hiera('management_vip')
  $verbose                    = pick($cinder_hash['verbose'], true)
  $debug                      = pick($cinder_hash['debug'], hiera('debug', true))
  $node_volumes               = hiera('node_volumes', [])
  $storage_hash               = hiera_hash('storage', {})
  $rabbit_hash                = hiera_hash('rabbit', {})
  $ceilometer_hash            = hiera_hash('ceilometer', {})
  $use_stderr                 = hiera('use_stderr', false)
  $use_syslog                 = hiera('use_syslog', true)
  $syslog_log_facility_cinder = hiera('syslog_log_facility_cinder', 'LOG_LOCAL3')
  $syslog_log_facility_ceph   = hiera('syslog_log_facility_ceph','LOG_LOCAL0')
  $proxy_port                 = hiera('proxy_port', '8080')
  $kombu_compression          = hiera('kombu_compression', '')

  $keystone_user              = pick($cinder_hash['user'], 'cinder')
  $keystone_tenant            = pick($cinder_hash['tenant'], 'services')

  $db_type      = 'mysql'
  $db_host      = pick($cinder_hash['db_host'], hiera('database_vip'))
  $db_user      = pick($cinder_hash['db_user'], 'cinder')
  $db_password  = $cinder_hash[db_password]
  $db_name      = pick($cinder_hash['db_name'], 'cinder')
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

  $ssl_hash                = hiera_hash('use_ssl', {})
  $service_endpoint        = hiera('service_endpoint')

  $keystone_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $keystone_auth_host      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

  $glance_protocol         = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_endpoint         = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])
  $glance_internal_ssl     = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)

  $swift_internal_protocol = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
  $swift_internal_address  = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$management_vip])

  $swift_url = "${swift_internal_protocol}://${swift_internal_address}:${proxy_port}"

  if $glance_internal_ssl {
    $glance_api_servers = "${glance_protocol}://${glance_endpoint}:9292"
  } else {
    $glance_api_servers = hiera('glance_api_servers', "http://${management_vip}:9292")
  }

  $service_port = '5000'
  $auth_uri     = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"

  $queue_provider = hiera('queue_provider', 'rabbit')
  if $queue_provider == 'rabbitmq'{
    $rpc_backend    = 'rabbit'
  } else {
    $rpc_backend = $queue_provider
  }

  if (!empty(get_nodes_hash_by_roles($network_metadata, ['ceph-osd'])) or
    $storage_hash['volumes_ceph'] or
    $storage_hash['images_ceph'] or
    $storage_hash['objects_ceph']
  ) {
    $use_ceph = true
  } else {
    $use_ceph = false
  }

  # SQLAlchemy backend configuration
  $max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
  $max_overflow = min($::processorcount * 5 + 0, 60 + 0)
  $max_retries = '-1'
  $idle_timeout = '3600'

  # Determine who should get the volume service

  if (roles_include(['cinder']) and $storage_hash['volumes_lvm']) {
    $manage_volumes = 'iscsi'
    $physical_volumes = false
    $volume_backend_name = $storage_hash['volume_backend_names']['volumes_lvm']
  } elsif roles_include(['cinder-vmware']) {
    $manage_volumes = 'vmdk'
    $physical_volumes = false
  } elsif ($storage_hash['volumes_ceph']) {
    $manage_volumes = 'ceph'
    $physical_volumes = false
    $volume_backend_name = $storage_hash['volume_backend_names']['volumes_ceph']
  } elsif (roles_include(['cinder-block-device']) and $storage_hash['volumes_block_device']) {
    $manage_volumes = 'block'
    $physical_volumes = join(get_disks_list_by_role($node_volumes, 'cinder-block-device'), ',')
    $volume_backend_name = $storage_hash['volume_backend_names']['volumes_block_device']
  } else {
    $physical_volumes = false
    $manage_volumes = false
    $volume_backend_name = false
  }

  Exec { logoutput => true }


  #################################################################
  # we need to evaluate ceph here, because ceph notifies/requires
  # other services that are declared in openstack manifests
  # TODO(xarses): somone needs to refactor this out
  # https://bugs.launchpad.net/fuel/+bug/1558831
  if ($use_ceph and !$storage_hash['volumes_lvm'] and !roles_include(['cinder-vmware'])) {

    prepare_network_config(hiera_hash('network_scheme', {}))
    $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
    $ceph_public_network  = get_network_role_property('ceph/public', 'network')


    class {'::ceph':
      primary_mon              => hiera('ceph_primary_monitor_node'),
      mon_hosts                => nodes_with_roles(['primary-controller', 'controller', 'ceph-mon'], 'name'),
      mon_ip_addresses         => get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller', 'ceph-mon']), 'mgmt/vip'),
      cluster_node_address     => $public_vip,
      osd_pool_default_size    => $storage_hash['osd_pool_size'],
      osd_pool_default_pg_num  => $storage_hash['pg_num'],
      osd_pool_default_pgp_num => $storage_hash['pg_num'],
      cluster_network          => $ceph_cluster_network,
      public_network           => $ceph_public_network,
      use_syslog               => $use_syslog,
      syslog_log_facility      => $syslog_log_facility_ceph,
      ephemeral_ceph           => $storage_hash['ephemeral_ceph']
    }
  }

  #################################################################

  include ::keystone::python

  #FIXME(bogdando) notify services on python-amqp update, if needed
  package { 'python-amqp':
    ensure => present
  }

  if !roles_include(['controller', 'primary-controller']) {
    # Configure auth_strategy on cinder node, if cinder and controller are
    # on the same node this parameter is configured by ::cinder::api
    cinder_config {
      'DEFAULT/auth_strategy': value => 'keystone';
    }
  }

  cinder_config { 'keymgr/fixed_key':
    value => $cinder_hash[fixed_key];
  }

  include cinder::params

  class {'cinder::glance':
    glance_api_servers => $glance_api_servers,
    # Glance API v2 is required for Ceph RBD backend
    glance_api_version => '2',
  }

  class { '::cinder':
    rpc_backend            => $rpc_backend,
    rabbit_hosts           => split(hiera('amqp_hosts',''), ','),
    rabbit_userid          => $rabbit_hash['user'],
    rabbit_password        => $rabbit_hash['password'],
    rabbit_ha_queues       => hiera('rabbit_ha_queues', false),
    database_connection    => $db_connection,
    verbose                => $verbose,
    use_syslog             => $use_syslog,
    use_stderr             => $use_stderr,
    log_facility           => hiera('syslog_log_facility_cinder', 'LOG_LOCAL3'),
    debug                  => $debug,
    database_idle_timeout  => $idle_timeout,
    database_max_pool_size => $max_pool_size,
    database_max_retries   => $max_retries,
    database_max_overflow  => $max_overflow,
    control_exchange       => 'cinder',
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
      service { $::cinder::params::tgt_service_name:
        ensure => stopped,
        enable => false,
      }
    }

    # NOTE(bogdando) deploy cinder volume node with disabled cinder-volume
    #   service #LP1398817. The orchestration will start and enable it back
    #   after the deployment is done.
    class { 'cinder::volume':
      enabled    => false,
    }

    class { 'cinder::backends':
      enabled_backends => [$volume_backend_name],
    }

    # TODO(xarses): clean up static vars
    $rbd_pool         = 'volumes'
    $rbd_user         = 'volumes'
    $rbd_secret_uuid  = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455'

    case $manage_volumes {
      true, 'iscsi': {
        cinder::backend::iscsi { $volume_backend_name:
          iscsi_ip_address    => $iscsi_bind_host,
          volume_group        => $volume_group,
          volume_backend_name => $volume_backend_name,
        }
        class { 'mellanox_openstack::cinder':
          iser            => $storage_hash['iser'],
          iser_ip_address => $iscsi_bind_host,
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
          Cinder::Backend::Rbd[$volume_backend_name]
        }

        cinder::backend::rbd { $volume_backend_name:
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
      'block': {
        cinder::backend::bdd { "${volume_backend_name}":
          iscsi_ip_address    => $iscsi_bind_host,
          volume_group        => $volume_group,
          volume_backend_name => $volume_backend_name,
          available_devices   => $physical_volumes,
        }
      }
    }
  }

  if $use_syslog {
    cinder_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  class { 'cinder::ceilometer':
    notification_driver => $ceilometer_hash['notification_driver'],
  }

  # TODO (iberezovskiy): remove this workaround in N when cinder module
  # will be switched to puppet-oslo usage for rabbit configuration
  if $kombu_compression in ['gzip','bz2'] {
    if !defined(Oslo::Messaging_rabbit['cinder_config']) and !defined(Cinder_config['oslo_messaging_rabbit/kombu_compression']) {
      cinder_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
    } else {
      Cinder_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
    }
  }

  #################################################################

  # vim: set ts=2 sw=2 et :

}
