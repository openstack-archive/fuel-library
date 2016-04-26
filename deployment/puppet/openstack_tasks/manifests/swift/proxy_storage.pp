class openstack_tasks::swift::proxy_storage {

  notice('MODULAR: swift/proxy_storage.pp')

  $network_scheme             = hiera_hash('network_scheme', {})
  $network_metadata           = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $swift_hash                 = hiera_hash('swift')
  $swift_master_role          = hiera('swift_master_role', 'primary-controller')
  $swift_nodes                = hiera_hash('swift_nodes', {})
  $swift_operator_roles       = pick($swift_hash['swift_operator_roles'], ['admin', 'SwiftOperator', '_member_'])
  $swift_proxies_addr_list    = values(get_node_to_ipaddr_map_by_network_role(hiera_hash('swift_proxies', {}), 'swift/api'))
  $memcaches_addr_list        = hiera('memcached_addresses')
  $is_primary_swift_proxy     = hiera('is_primary_swift_proxy', false)
  $proxy_port                 = hiera('proxy_port', '8080')
  $storage_hash               = hiera_hash('storage')
  $management_vip             = hiera('management_vip')
  $swift_api_ipaddr           = get_network_role_property('swift/api', 'ipaddr')
  $swift_storage_ipaddr       = get_network_role_property('swift/replication', 'ipaddr')
  $debug                      = pick($swift_hash['debug'], hiera('debug', false))
  $verbose                    = pick($swift_hash['verbose'], hiera('verbose', false))
# NOTE(mattymo): Changing ring_part_power or part_hours on redeploy leads to data loss
  $ring_part_power            = pick($swift_hash['ring_part_power'], 10)
  $ring_min_part_hours        = hiera('swift_ring_min_part_hours', 1)
  $deploy_swift_proxy         = hiera('deploy_swift_proxy', true)
#Keystone settings
  $keystone_user              = pick($swift_hash['user'], 'swift')
  $keystone_password          = pick($swift_hash['user_password'], 'passsword')
  $keystone_tenant            = pick($swift_hash['tenant'], 'services')
  $workers_max                = hiera('workers_max', 16)
  $service_workers            = pick($swift_hash['workers'],
                                  min(max($::processorcount, 2), $workers_max))
  $ssl_hash                   = hiera_hash('use_ssl', {})
  $rabbit_hash                = hiera_hash('rabbit')
  $rabbit_hosts               = hiera('amqp_hosts')
#storage settings
  $mp_hash                    = hiera('mp')
  $deploy_swift_storage       = hiera('deploy_swift_storage', true)

  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [pick($swift_hash['auth_protocol'], 'http')])
  $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('service_endpoint', ''), $management_vip])
  $admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', [pick($swift_hash['auth_protocol'], 'http')])
  $admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('service_endpoint', ''), $management_vip])

  $auth_uri     = "${internal_auth_protocol}://${internal_auth_address}:5000/"
  $identity_uri = "${admin_auth_protocol}://${admin_auth_address}:35357/"

  $swift_internal_protocol    = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
  $swift_internal_address    = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$swift_api_ipaddr, $management_vip])

  $swift_proxies_num = size(hiera('swift_proxies'))

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
    $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
    $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
    $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
    $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')
    $swift_partition               = hiera('swift_partition', '/var/lib/glance/node')

    if $is_primary_swift_proxy {
      ring_devices {'all':
        storages => $swift_nodes,
        require  => Class['swift'],
      }
    }

    if ($swift_proxies_num < 2) {
      $ring_replicas = 2
    } else {
      $ring_replicas = 3
    }

    if $deploy_swift_proxy {
      class { 'openstack::swift::proxy':
        swift_user_password            => $swift_hash['user_password'],
        swift_operator_roles           => $swift_operator_roles,
        swift_proxies_cache            => $memcaches_addr_list,
        cache_server_port              => hiera('memcache_server_port', '11211'),
        ring_part_power                => $ring_part_power,
        ring_replicas                  => $ring_replicas,
        primary_proxy                  => $is_primary_swift_proxy,
        swift_proxy_local_ipaddr       => $swift_api_ipaddr,
        swift_replication_local_ipaddr => $swift_storage_ipaddr,
        master_swift_proxy_ip          => $master_swift_proxy_ip,
        master_swift_replication_ip    => $master_swift_replication_ip,
        proxy_port                     => $proxy_port,
        proxy_workers                  => $service_workers,
        debug                          => $debug,
        verbose                        => $verbose,
        log_facility                   => 'LOG_SYSLOG',
        ceilometer                     => hiera('use_ceilometer',false),
        ring_min_part_hours            => $ring_min_part_hours,
        admin_user                     => $keystone_user,
        admin_tenant_name              => $keystone_tenant,
        admin_password                 => $keystone_password,
        auth_host                      => $internal_auth_address,
        auth_protocol                  => $internal_auth_protocol,
        auth_uri                       => $auth_uri,
        identity_uri                   => $identity_uri,
        rabbit_user                    => $rabbit_hash['user'],
        rabbit_password                => $rabbit_hash['password'],
        rabbit_hosts                   => split($rabbit_hosts, ', '),
      }

      # Check swift proxy and internal VIP are from the same IP network. If no
      # then it's possible to get network failure, so proxy couldn't access
      # Keystone via VIP. In such cases swift health check returns OK, but all
      # requests forwarded from HAproxy fail, see LP#1459772 In order to detect
      # such bad swift backends we enable a service which checks Keystone
      # availability from swift node. HAProxy monitors that service to get
      # proper backend status.
      # NOTE: this is the same logic in the HAproxy configuration so if it's
      # updated there, this must be updated. See LP#1548275
      $swift_api_network = get_network_role_property('swift/api', 'network')
      $bind_to_one       = has_ip_in_network($management_vip, $swift_api_network)

      if !$bind_to_one {
        $storage_nets = get_routable_networks_for_network_role($network_scheme, 'swift/replication', ' ')
        $mgmt_nets = get_routable_networks_for_network_role($network_scheme, 'swift/api', ' ')

        class { 'openstack::swift::status':
          endpoint    => "${swift_internal_protocol}://${swift_internal_address}:${proxy_port}",
          scan_target => "${internal_auth_address}:5000",
          only_from   => "127.0.0.1 240.0.0.2 ${storage_nets} ${mgmt_nets}",
          con_timeout => 5
        }

        Class['openstack::swift::status'] -> Class['swift::dispersion']
      }

      class { 'swift::dispersion':
        auth_url       => "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0/",
        auth_user      =>  $keystone_user,
        auth_tenant    =>  $keystone_tenant,
        auth_pass      =>  $keystone_password,
        auth_version   =>  '2.0',
      }

      Class['openstack::swift::proxy'] -> Class['swift::dispersion']
      Service<| tag == 'swift-service' |> -> Class['swift::dispersion']
    }

    if ($deploy_swift_storage){
      if !defined(File['/var/lib/glance']) {
        file {'/var/lib/glance':
          ensure  => 'directory',
          group   => 'swift',
          require => Package['swift'],
        } -> Service <| tag == 'swift-service' |>
      } else {
        File['/var/lib/glance'] {
          ensure  => 'directory',
          group   => 'swift',
          require +> Package['swift'],
        }
        File['/var/lib/glance'] -> Service <| tag == 'swift-service' |>
      }

      class { 'openstack::swift::storage_node':
        storage_type                => false,
        loopback_size               => '5243780',
        storage_mnt_base_dir        => $swift_partition,
        storage_devices             => filter_hash($mp_hash,'point'),
        swift_zone                  => $master_swift_proxy_nodes_list[0]['swift_zone'],
        swift_local_net_ip          => $swift_storage_ipaddr,
        master_swift_proxy_ip       => $master_swift_proxy_ip,
        master_swift_replication_ip => $master_swift_replication_ip,
        sync_rings                  => ! $is_primary_swift_proxy,
        debug                       => $debug,
        verbose                     => $verbose,
        log_facility                => 'LOG_SYSLOG',
      }
    }
  }

  # FIXME(bogdando) requires decomposition and unit tests
  class openstack::swift::status (
    $address     = '0.0.0.0',
    $only_from   = '127.0.0.1',
    $port        = '49001',
    $endpoint    = 'http://127.0.0.1:8080',
    $scan_target = '127.0.0.1:5000',
    $con_timeout = '5',
  ) {

    augeas { 'swiftcheck':
      context => '/files/etc/services',
      changes => [
        "set /files/etc/services/service-name[port = '${port}']/port ${port}",
        "set /files/etc/services/service-name[port = '${port}'] swiftcheck",
        "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
        "set /files/etc/services/service-name[port = '${port}']/#comment 'Swift Health Check'",
      ],
    }

    $group = $::osfamily ? {
      'RedHat' => 'nobody',
      'Debian' => 'nogroup',
      default  => 'nobody',
    }

    include xinetd
    xinetd::service { 'swiftcheck':
      bind        => $address,
      port        => $port,
      only_from   => $only_from,
      cps         => '512 10',
      per_source  => 'UNLIMITED',
      server      => '/usr/bin/swiftcheck',
      server_args => "${endpoint} ${scan_target} ${con_timeout}",
      user        => 'nobody',
      group       => $group,
      flags       => 'IPv4',
      require     => Augeas['swiftcheck'],
    }
  }

  class openstack::swift::proxy (
    $swift_user_password               = 'swift_pass',
    $swift_hash_suffix                 = 'swift_secret',
    $swift_max_header_size             = '32768',
    $swift_proxy_local_ipaddr          = $::ipaddress_eth0,
    $swift_replication_local_ipaddr    = $::ipaddress_eth0,
    $ring_part_power                   = 18,
    $ring_replicas                     = 3,
    $ring_min_part_hours               = 1,
    $proxy_pipeline                    = [
      'catch_errors',
      'crossdomain',
      'healthcheck',
      'cache',
      'bulk',
      'tempurl',
      'ratelimit',
      'formpost',
      'swift3',
      's3token',
      'authtoken',
      'keystone',
      'staticweb',
      'container_quotas',
      'account_quotas',
      'slo',
      'proxy-server'],
    $proxy_workers                     = $::processorcount,
    $proxy_port                        = '8080',
    $proxy_allow_account_management    = true,
    $proxy_account_autocreate          = true,
    $ratelimit_clock_accuracy          = 1000,
    $ratelimit_max_sleep_time_seconds  = 60,
    $ratelimit_log_sleep_time_seconds  = 0,
    $ratelimit_rate_buffer_seconds     = 5,
    $ratelimit_account_ratelimit       = 0,
    $package_ensure                    = 'present',
    $swift_proxies_cache               = ['127.0.0.1'],
    $cache_server_port                 = '11211',
    $primary_proxy                     = false,
    $swift_devices                     = undef,
    $master_swift_proxy_ip             = undef,
    $master_swift_replication_ip       = undef,
    $collect_exported                  = false,
    $rings                             = ['account', 'object', 'container'],
    $debug                             = false,
    $verbose                           = true,
    $log_facility                      = 'LOG_LOCAL1',
    $ceilometer                        = false,
    $admin_user                        = 'swift',
    $admin_tenant_name                 = 'services',
    $admin_password                    = 'password',
    $auth_host                         = '10.0.0.1',
    $auth_protocol                     = 'http',
    $auth_uri                          = 'http://127.0.0.1:5000',
    $identity_uri                      = 'http://127.0.0.1:35357',
    $swift_operator_roles              = ['admin', 'SwiftOperator'],
    $rabbit_user                       = 'guest',
    $rabbit_password                   = 'password',
    $rabbit_hosts                      = '127.0.0.1:5672',
  ) {
    if !defined(Class['swift']) {
      class { 'swift':
        swift_hash_suffix => $swift_hash_suffix,
        package_ensure    => $package_ensure,
        max_header_size   => $swift_max_header_size,
      }
    }

    if !defined(Class['rsync::server']) {
      class { '::rsync::server':
      use_xinetd => true,
      address    => $local_net_ip,
      use_chroot => 'no',
      }
    }

    # calculate log_level
    if $debug {
      $log_level = 'DEBUG'
    }
    elsif $verbose {
      $log_level = 'INFO'
    }
    else {
      $log_level = 'WARNING'
    }

    if $ceilometer {
      $new_proxy_pipeline = split(
        inline_template(
        "<%=
            @proxy_pipeline.insert(-2, 'ceilometer').join(',')
         %>"), ',')
      class { '::swift::proxy::ceilometer':
        rabbit_user     => $rabbit_user,
        rabbit_password => $rabbit_password,
        rabbit_hosts    => $rabbit_hosts,
      }
    }
    else {
      $new_proxy_pipeline = $proxy_pipeline
    }

    class { '::swift::proxy':
      proxy_local_net_ip       => $swift_proxy_local_ipaddr,
      pipeline                 => $new_proxy_pipeline,
      port                     => $proxy_port,
      workers                  => $proxy_workers,
      allow_account_management => $proxy_allow_account_management,
      account_autocreate       => $proxy_account_autocreate,
      package_ensure           => $package_ensure,
      log_facility             => $log_facility,
      log_level                => $log_level,
      log_name                 => 'swift-proxy-server',
    }

    # configure all of the middlewares
    class { ['::swift::proxy::catch_errors', '::swift::proxy::crossdomain', '::swift::proxy::healthcheck',
    '::swift::proxy::bulk', '::swift::proxy::tempurl', '::swift::proxy::formpost', '::swift::proxy::swift3',
    '::swift::proxy::staticweb', '::swift::proxy::container_quotas', '::swift::proxy::account_quotas',
    '::swift::proxy::slo',]:
    }

    $cache_addresses = join(suffix($swift_proxies_cache, ":${cache_server_port}"), ',')

    class { '::swift::proxy::cache': memcache_servers => split($cache_addresses, ',') }

    class { '::swift::proxy::ratelimit':
      clock_accuracy         => $ratelimit_clock_accuracy,
      max_sleep_time_seconds => $ratelimit_max_sleep_time_seconds,
      log_sleep_time_seconds => $ratelimit_log_sleep_time_seconds,
      rate_buffer_seconds    => $ratelimit_rate_buffer_seconds,
      account_ratelimit      => $ratelimit_account_ratelimit,
    }

    class { '::swift::proxy::s3token':
      auth_host     => $auth_host,
      auth_port     => '35357',
      auth_protocol => $auth_protocol,
    }

    class { '::swift::proxy::keystone':
      operator_roles => $swift_operator_roles,
    }

    class { '::swift::proxy::authtoken':
      admin_user        => $admin_user,
      admin_tenant_name => $admin_tenant_name,
      admin_password    => $admin_password,
      auth_uri          => $auth_uri,
      identity_uri      => $identity_uri,
    }

    if $primary_proxy {
      # we need to exec swift ringrebuilder commands under swift user
      Exec { user => 'swift' }
      # Exit codes should be equal to 0 and 1 (bug #1402701)
      Exec <| title == "rebalance_account" or title == "rebalance_container" or title == "rebalance_object" |> { returns => [0,1] }

      # collect all of the resources that are needed
      # to balance the ring
      if $collect_exported {
        Ring_object_device <<| tag == "${::deployment_id}::${::environment}" |>>
        Ring_container_device <<| tag == "${::deployment_id}::${::environment}" |>>
        Ring_account_device <<| tag == "${::deployment_id}::${::environment}" |>>
      }

      # create the ring
      class { 'swift::ringbuilder':
        # the part power should be determined by assuming 100 partitions per drive
        part_power     => $ring_part_power,
        replicas       => $ring_replicas,
        min_part_hours => $ring_min_part_hours,
        require        => Class['swift'],
        before         => [Class['::swift::proxy']],
      }

      # sets up an rsync db that can be used to sync the ring DB
      class { 'swift::ringserver':
        local_net_ip => $swift_replication_local_ipaddr,
      }

      rsync::server::module { 'swift_backups':
        path            => '/etc/swift/backups',
        lock_file       => '/var/lock/swift_backups.lock',
        uid             => 'swift',
        gid             => 'swift',
        incoming_chmod  => false,
        outgoing_chmod  => false,
        max_connections => '5',
        read_only       => true,
      }

      # resource ordering
      Swift::Ringbuilder::Rebalance <||> -> Service['swift-proxy-server']
      Swift::Ringbuilder::Rebalance <||> -> Swift::Storage::Generic <| |>
      Swift::Ringbuilder::Create<||> ->
      Ring_devices<||> ~>
      Swift::Ringbuilder::Rebalance <||>
    } else {
      validate_string($master_swift_replication_ip)

      if member($rings, 'account') and ! defined(Swift::Ringsync['account']) {
        swift::ringsync { 'account': ring_server => $master_swift_replication_ip }
      }

      if member($rings, 'object') and ! defined(Swift::Ringsync['object']) {
        swift::ringsync { 'object': ring_server => $master_swift_replication_ip }
      }

      if member($rings, 'container') and ! defined(Swift::Ringsync['container']) {
        swift::ringsync { 'container': ring_server => $master_swift_replication_ip }
      }

      rsync::get { "/etc/swift/backups/":
        source    => "rsync://${master_swift_replication_ip}/swift_backups/",
        recursive => true,
      }

      Swift::Ringsync <| |> ~> Service['swift-proxy-server']
    }
  }

  # FIXME(bogdando) requires decomposition and unit tests
  class openstack::swift::storage_node (
    $swift_zone,
    $swift_hash_suffix          = 'swift_secret',
    $swift_max_header_size      = '32768',
    $swift_local_net_ip         = $::ipaddress_eth0,
    $storage_type               = 'loopback',
    $storage_base_dir           = '/srv/loopback-device',
    $storage_mnt_base_dir       = '/srv/node',
    $storage_devices            = [
      '1',
      '2'],
    $storage_weight             = 1,
    $package_ensure             = 'present',
    $loopback_size              = '1048756',
    $master_swift_proxy_ip,
    $master_swift_replication_ip,
    $rings                      = [
      'account',
      'object',
      'container'],
    $sync_rings                 = true,
    $incoming_chmod             = 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
    $outgoing_chmod             = 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
    # if the cinder management components should be installed
    $cinder                     = true,
    $manage_volumes             = false,
    $nv_physical_volume         = undef,
    $cinder_volume_group        = 'cinder-volumes',
    $cinder_user_password       = 'cinder_user_pass',
    $cinder_db_password         = 'cinder_db_pass',
    $cinder_db_user             = 'cinder',
    $cinder_db_dbname           = 'cinder',
    $cinder_iscsi_bind_addr     = false,
    $cinder_rate_limits         = false,
    $db_host                    = '127.0.0.1',
    $service_endpoint           = '127.0.0.1',
    $use_syslog                 = false,
    $syslog_log_facility_cinder = 'LOG_LOCAL3',
    $debug                      = false,
    $verbose                    = true,
    # Rabbit details necessary for cinder
    $rabbit_nodes               = false,
    $rabbit_password            = 'rabbit_pw',
    $rabbit_host                = false,
    $rabbit_user                = 'nova',
    $rabbit_ha_virtual_ip       = false,
    $queue_provider             = 'rabbitmq',
    $qpid_password              = 'qpid_pw',
    $qpid_user                  = 'nova',
    $qpid_nodes                 = ['127.0.0.1'],
    $log_facility               = 'LOG_LOCAL2',
    ) {
    if !defined(Class['swift']) {
      class { 'swift':
        swift_hash_suffix => $swift_hash_suffix,
        package_ensure    => $package_ensure,
        max_header_size   => $swift_max_header_size,
      }
    }

    if $storage_type == 'loopback' {
      # create xfs partitions on a loopback device and mount them
      swift::storage::loopback { $storage_devices:
        base_dir     => $storage_base_dir,
        mnt_base_dir => $storage_mnt_base_dir,
        seek         => $loopback_size,
        require      => Class['swift'],
      }
    }

    # create dirs for devices
    define device_directory($devices) {
      if(!defined(File[$devices])) {
        file { $devices:
          ensure       => 'directory',
          owner        => 'swift',
          group        => 'swift',
          recurse      => true,
          recurselimit => 1,
        }
      }
    }
    if ($storage_devices != undef) {
      anchor {'swift-device-directories-start': } ->
      device_directory { $storage_devices:
        devices => $storage_mnt_base_dir,
      }
    }

    # install all swift storage servers together
    class { 'swift::storage::all':
      storage_local_net_ip => $swift_local_net_ip,
      devices              => $storage_mnt_base_dir,
      log_facility         => $log_facility,
      # We use directory for swift
      mount_check          => false,
    }
    # override log_name defaults for Swift::Storage::Server
    # TODO (adidenko) move this into Hiera when it's ready
    Swift::Storage::Server <| title == '6000' |> {
      log_name => 'swift-object-server',
    }
    Swift::Storage::Server <| title == '6001' |> {
      log_name       => 'swift-container-server',
      allow_versions => true,
    }
    Swift::Storage::Server <| title == '6002' |> {
      log_name => 'swift-account-server',
    }

    Swift::Storage::Server <| |> {
      incoming_chmod => $incoming_chmod,
      outgoing_chmod => $outgoing_chmod,
    }

    validate_string($master_swift_replication_ip)

    if $sync_rings {
      if member($rings, 'account') and !defined(Swift::Ringsync['account']) {
        swift::ringsync { 'account': ring_server => $master_swift_replication_ip }
      }

      if member($rings, 'object') and !defined(Swift::Ringsync['object']) {
        swift::ringsync { 'object': ring_server => $master_swift_replication_ip }
      }

      if member($rings, 'container') and !defined(Swift::Ringsync['container']) {
        swift::ringsync { 'container': ring_server => $master_swift_replication_ip }
      }
      Swift::Ringsync <| |> ~> Class["swift::storage::all"]
    }
  }
}
