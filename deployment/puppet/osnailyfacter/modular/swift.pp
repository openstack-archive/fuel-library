$swift_hash = hiera('swift_hash')
$storage_hash = hiera('storage_hash')

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

if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
  $mp_hash              = hiera('mp')
  $mountpoints = filter_hash($mp_hash,'point')
  $storage_devices = $mountpoints
  $swift_partition = '/var/lib/glance/node'
  $swift_proxies            = hiera('controller_internal_addresses')
  $controllers = hiera('controllers')
  $swift_local_net_ip       = hiera('storage_address')
  $master_swift_proxy_nodes = hiera('primary_controller_nodes')
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
  $swift_loopback = false
  if hiera('primary_controller') {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }
  $log_facility = 'LOG_SYSLOG'
  $sync_rings            = ! $primary_proxy

  class { 'swift::keystone::auth':
    password         => $swift_hash['user_password'],
    public_address   => hiera('public_vip'),
    internal_address => hiera('management_vip'),
    admin_address    => hiera('management_vip'),
  }

  $node = hiera('node')
  $swift_zone = $node[0]['swift_zone']
  if $primary_proxy {
    ring_devices {'all':
      storages => $controllers,
      require  => Class['swift'],
    }
  }

  if !$swift_hash['resize_value'] { $swift_hash['resize_value'] = 2 }

  $ring_part_power=calc_ring_part_power($controllers,$swift_hash['resize_value'])

  ############STORAGE
  if !defined(Class['swift']) {
    class { 'swift':
      swift_hash_suffix => 'swift_secret',
      package_ensure    => 'present',
    }
  }

  $storage_mnt_base_dir  = $swift_partition ## !!!!!!!!!!!!

  if ($storage_devices != undef) {
    anchor {'swift-device-directories-start': } ->
    device_directory { $mountpoints:
      devices => $storage_mnt_base_dir,
    }
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
    devices              => $storage_mnt_base_dir,
    log_facility         => $log_facility,
  }
  # override log_name defaults for Swift::Storage::Server
  # TODO (adidenko) move this into Hiera when it's ready
  Swift::Storage::Server <| title == '6000' |> {
    log_name => 'swift-object-server',
  }
  Swift::Storage::Server <| title == '6001' |> {
    log_name => 'swift-container-server',
  }
  Swift::Storage::Server <| title == '6002' |> {
    log_name => 'swift-account-server',
  }

  validate_string($master_swift_proxy_ip)

  $rings   = [
    'account',
    'object',
    'container'
  ]

  if $sync_rings {
    if member($rings, 'account') and !defined(Swift::Ringsync['account']) {
      swift::ringsync { 'account': ring_server => $master_swift_proxy_ip }
    }

    if member($rings, 'object') and !defined(Swift::Ringsync['object']) {
      swift::ringsync { 'object': ring_server => $master_swift_proxy_ip }
    }
    if member($rings, 'container') and !defined(Swift::Ringsync['container']) {
      swift::ringsync { 'container': ring_server => $master_swift_proxy_ip }
    }
    Swift::Ringsync <| |> ~> Class["swift::storage::all"]
  }

  ###########Proxy

  # calculate log_level
  if (hiera('debug')) {
    $log_level = 'DEBUG'
  }
  elsif (hiera('verbose')) {
    $log_level = 'INFO'
  }
  else {
    $log_level = 'WARNING'
  }

  $proxy_pipeline = [
    'catch_errors',
    'healthcheck',
    'cache',
    'ratelimit',
    'swift3',
    's3token',
    'authtoken',
    'keystone',
    'proxy-server']

  class { '::swift::proxy':
    proxy_local_net_ip       => $swift_local_net_ip,
    pipeline                 => $proxy_pipeline,
    port                     => '8080',
    workers                  => $::processorcount,
    allow_account_management => true,
    account_autocreate       => true ,
    package_ensure           => 'present',
    log_facility             => $log_facility,
    log_level                => $log_level,
    log_name                 => 'swift-proxy-server',
  }

  # configure all of the middlewares
  class { ['::swift::proxy::catch_errors', '::swift::proxy::healthcheck', '::swift::proxy::swift3',]: }

  $cache_addresses = inline_template("<%= @swift_proxies.keys.uniq.sort.collect {|ip| ip + ':11211' }.join ',' %>")

  class { '::swift::proxy::cache': memcache_servers => split($cache_addresses, ',') }

  class { '::swift::proxy::ratelimit':
    clock_accuracy         => 1000, #$ratelimit_clock_accuracy,
    max_sleep_time_seconds => 60, #$ratelimit_max_sleep_time_seconds,
    log_sleep_time_seconds => 0, #$ratelimit_log_sleep_time_seconds,
    rate_buffer_seconds    => 5, #$ratelimit_rate_buffer_seconds,
    account_ratelimit      => 0, #$ratelimit_account_ratelimit,
  }

  class { '::swift::proxy::s3token':
    auth_host => hiera('management_vip'),
    auth_port => '35357',
  }

  class { '::swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }

  class { '::swift::proxy::authtoken':
    admin_user        => 'swift',
    admin_tenant_name => 'services',
    admin_password    => $swift_hash[user_password], #$swift_user_password,
    auth_host         => hiera('management_vip'), #$controller_node_address,
  }

  if $primary_proxy {
    # collect all of the resources that are needed
    # to balance the ring
    #    if $collect_exported {
    #      Ring_object_device <<| tag == "${::deployment_id}::${::environment}" |>>
    #        Ring_container_device <<| tag == "${::deployment_id}::${::environment}" |>>
    #      Ring_account_device <<| tag == "${::deployment_id}::${::environment}" |>>
    #    }

    # create the ring
    class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
      part_power     => $ring_part_power,
      replicas       => 3, #$ring_replicas,
      min_part_hours => 1, #$ring_min_part_hours,
      require        => Class['swift'],
      before         => [Class['::swift::proxy']],
    }

    # sets up an rsync db that can be used to sync the ring DB
    class { 'swift::ringserver':  local_net_ip => $swift_local_net_ip, }

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

    Swift::Ringsync <| |> ~> Service["swift-proxy"]
  }

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  cluster::haproxy_service { 'swift':
    order        => '120',
    listen_port  => 8080,
    server_names => filter_hash(hiera('controllers'), 'name'),
    ipaddresses  => filter_hash(hiera('controllers'), 'storage_address'),
    public_virtual_ip      => hiera('public_vip'),
    internal_virtual_ip    => hiera('management_vip'),
    public       => true,
  }

}
