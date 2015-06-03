#
class openstack::swift::proxy (
  $swift_user_password                = 'swift_pass',
  $swift_hash_suffix                  = 'swift_secret',
  $swift_local_net_ip                 = $::ipaddress_eth0,
  $ring_part_power                    = 18,
  $ring_replicas                      = 3,
  $ring_min_part_hours                = 1,
  $proxy_pipeline                     = [
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
  $proxy_workers                      = $::processorcount,
  $proxy_port                         = '8080',
  $proxy_allow_account_management     = true,
  $proxy_account_autocreate           = true,
  $ratelimit_clock_accuracy           = 1000,
  $ratelimit_max_sleep_time_seconds   = 60,
  $ratelimit_log_sleep_time_seconds   = 0,
  $ratelimit_rate_buffer_seconds      = 5,
  $ratelimit_account_ratelimit        = 0,
  $package_ensure                     = 'present',
  $controller_node_address            = '10.0.0.1',
  $swift_proxies                      = {
    '127.0.0.1' => '127.0.0.1'
  }
  ,
  $primary_proxy                      = false,
  $swift_devices                      = undef,
  $master_swift_proxy_ip              = undef,
  $collect_exported                   = false,
  $rings                              = ['account', 'object', 'container'],
  $debug                              = false,
  $verbose                            = true,
  $log_facility                       = 'LOG_LOCAL1',
  $ceilometer                         = false,
) {
  if !defined(Class['swift']) {
    class { 'swift':
      swift_hash_suffix => $swift_hash_suffix,
      package_ensure    => $package_ensure,
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

  #FIXME(bogdando) the memcached class must be included in catalog if swift node is a standalone!

  if $ceilometer {
    $new_proxy_pipeline = split(
      inline_template(
      "<%=
          @proxy_pipeline.insert(-2, 'ceilometer').join(',')
       %>"), ',')
    class { '::swift::proxy::ceilometer': }
  }
  else {
    $new_proxy_pipeline = $proxy_pipeline
  }

  class { '::swift::proxy':
    proxy_local_net_ip       => $swift_local_net_ip,
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

  $cache_addresses = inline_template("<%= @swift_proxies.values.uniq.sort.collect {|ip| ip + ':11211' }.join ',' %>")

  class { '::swift::proxy::cache': memcache_servers => split($cache_addresses, ',') }

  class { '::swift::proxy::ratelimit':
    clock_accuracy         => $ratelimit_clock_accuracy,
    max_sleep_time_seconds => $ratelimit_max_sleep_time_seconds,
    log_sleep_time_seconds => $ratelimit_log_sleep_time_seconds,
    rate_buffer_seconds    => $ratelimit_rate_buffer_seconds,
    account_ratelimit      => $ratelimit_account_ratelimit,
  }

  class { '::swift::proxy::s3token':
    auth_host => $controller_node_address,
    auth_port => '35357',
  }

  class { '::swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }

  class { '::swift::proxy::authtoken':
    admin_user        => 'swift',
    admin_tenant_name => 'services',
    admin_password    => $swift_user_password,
    auth_host         => $controller_node_address,
  }

  if $primary_proxy {
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
      local_net_ip => $swift_local_net_ip,
    }

    # resource ordering
    Anchor <| title == 'rebalance_end' |> -> Service['swift-proxy']
    Anchor <| title == 'rebalance_end' |> -> Swift::Storage::Generic <| |>
    Swift::Ringbuilder::Create<||> ->
    Ring_devices<||> ~>
    Swift::Ringbuilder::Rebalance <||>

 } else {
    validate_string($master_swift_proxy_ip)

    if member($rings, 'account') and ! defined(Swift::Ringsync['account']) {
      swift::ringsync { 'account': ring_server => $master_swift_proxy_ip }
    }

    if member($rings, 'object') and ! defined(Swift::Ringsync['object']) {
      swift::ringsync { 'object': ring_server => $master_swift_proxy_ip }
    }

    if member($rings, 'container') and ! defined(Swift::Ringsync['container']) {
      swift::ringsync { 'container': ring_server => $master_swift_proxy_ip }
    }

    rsync::get { "/etc/swift/backups/":
      source    => "rsync://${master_swift_proxy_ip}/swift_server/backups/",
      recursive => true,
    }

    Swift::Ringsync <| |> ~> Service["swift-proxy"]
  }
}
