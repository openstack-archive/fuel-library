class openstack_tasks::swift::parts::proxy (
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
      swift_hash_path_suffix => $swift_hash_suffix,
      package_ensure         => $package_ensure,
      max_header_size        => $swift_max_header_size,
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
    Swift::Ringbuilder::Rebalance <||> -> Service <| tag == swift-service |>
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

    anchor { 'openstack_tasks_proxy_start' :} ->
    Swift::Ringsync <| |> ~>
    Service['swift-proxy-server'] ->
    anchor { 'openstack_tasks_proxy_end' :}

  }
}
