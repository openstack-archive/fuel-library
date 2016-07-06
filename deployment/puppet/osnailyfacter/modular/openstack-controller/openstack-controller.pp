notice('MODULAR: openstack-controller.pp')

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$nova_rate_limits               = hiera('nova_rate_limits')
$primary_controller             = hiera('primary_controller')
$use_neutron                    = hiera('use_neutron', false)
$nova_report_interval           = hiera('nova_report_interval')
$nova_service_down_time         = hiera('nova_service_down_time')
$use_syslog                     = hiera('use_syslog', true)
$use_stderr                     = hiera('use_stderr', false)
$syslog_log_facility_glance     = hiera('syslog_log_facility_glance', 'LOG_LOCAL2')
$syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
$syslog_log_facility_nova       = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$syslog_log_facility_keystone   = hiera('syslog_log_facility_keystone', 'LOG_LOCAL7')
$management_vip                 = hiera('management_vip')
$public_vip                     = hiera('public_vip')
$sahara_hash                    = hiera_hash('sahara', {})
$nodes_hash                     = hiera('nodes', {})
$mysql_hash                     = hiera_hash('mysql', {})
$access_hash                    = hiera_hash('access', {})
$keystone_hash                  = hiera_hash('keystone', {})
$glance_hash                    = hiera_hash('glance', {})
$storage_hash                   = hiera_hash('storage', {})
$nova_hash                      = hiera_hash('nova', {})
$nova_config_hash               = hiera_hash('nova_config', {})
$api_bind_address               = get_network_role_property('nova/api', 'ipaddr')
$rabbit_hash                    = hiera_hash('rabbit_hash', {})
$ceilometer_hash                = hiera_hash('ceilometer',{})
$syslog_log_facility_ceph       = hiera('syslog_log_facility_ceph','LOG_LOCAL0')
$workloads_hash                 = hiera_hash('workloads_collector', {})
$service_endpoint               = hiera('service_endpoint')
$db_host                        = pick($nova_hash['db_host'], hiera('database_vip'))
$nova_db_user                   = pick($nova_hash['db_user'], 'nova')
$keystone_user                  = pick($nova_hash['user'], 'nova')
$keystone_tenant                = pick($nova_hash['tenant'], 'services')
$glance_api_servers             = hiera('glance_api_servers', "$management_vip:9292")
$region                         = hiera('region', 'RegionOne')
$service_workers                = pick($nova_hash['workers'],
                                        min(max($::processorcount, 2), 16))
$memcached_servers              = hiera('memcached_servers')

$memcache_nodes                 = get_nodes_hash_by_roles(hiera('network_metadata'), hiera('memcache_roles'))
$memcache_ipaddrs               = ipsort(values(get_node_to_ipaddr_map_by_network_role($memcache_nodes,'mgmt/memcache')))
$roles                          = node_roles($nodes_hash, hiera('uid'))

$floating_hash = {}

if $use_neutron {
  $network_provider          = 'neutron'
  $novanetwork_params        = {}
  $neutron_config            = hiera_hash('quantum_settings')
  $neutron_db_password       = $neutron_config['database']['passwd']
  $neutron_user_password     = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                  = $neutron_config['L2']['base_mac']
} else {
  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
}

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

#################################################################
if hiera('use_vcenter', false) or hiera('libvirt_type') == 'vcenter' {
  $multi_host = false
} else {
  $multi_host = true
}

class { '::openstack::controller':
  private_interface              => $use_neutron ? { true=>false, default=>hiera('private_int')},
  public_interface               => hiera('public_int', undef),
  public_address                 => $public_vip,    # It is feature for HA mode.
  internal_address               => $management_vip,  # All internal traffic goes
  admin_address                  => $management_vip,  # through load balancer.
  floating_range                 => $use_neutron ? { true =>$floating_hash, default  =>false},
  fixed_range                    => $use_neutron ? { true =>false, default =>hiera('fixed_network_range')},
  multi_host                     => $multi_host,
  network_config                 => hiera('network_config', {}),
  num_networks                   => hiera('num_networks', undef),
  network_size                   => hiera('network_size', undef),
  network_manager                => hiera('network_manager', undef),
  network_provider               => $network_provider,
  verbose                        => true,
  debug                          => hiera('debug', true),
  auto_assign_floating_ip        => hiera('auto_assign_floating_ip', false),
  glance_api_servers             => $glance_api_servers,
  primary_controller             => $primary_controller,
  novnc_address                  => $api_bind_address,
  nova_db_user                   => $nova_db_user,
  nova_db_password               => $nova_hash[db_password],
  nova_user                      => $keystone_user,
  nova_user_password             => $nova_hash[user_password],
  nova_user_tenant               => $keystone_tenant,
  nova_hash                      => $nova_hash,
  queue_provider                 => 'rabbitmq',
  amqp_hosts                     => hiera('amqp_hosts',''),
  amqp_user                      => $rabbit_hash['user'],
  amqp_password                  => $rabbit_hash['password'],
  rabbit_ha_queues               => true,
  cache_server_ip                => $memcache_ipaddrs,
  api_bind_address               => $api_bind_address,
  db_host                        => $db_host,
  service_endpoint               => $service_endpoint,
  neutron_metadata_proxy_secret  => $neutron_metadata_proxy_secret,
  cinder                         => true,
  ceilometer                     => $ceilometer_hash[enabled],
  service_workers                => $service_workers,
  use_syslog                     => $use_syslog,
  use_stderr                     => $use_stderr,
  syslog_log_facility_nova       => $syslog_log_facility_nova,
  nova_rate_limits               => $nova_rate_limits,
  nova_report_interval           => $nova_report_interval,
  nova_service_down_time         => $nova_service_down_time,
  ha_mode                        => true,
  # SQLALchemy backend
  max_retries                    => $max_retries,
  max_pool_size                  => $max_pool_size,
  max_overflow                   => $max_overflow,
  idle_timeout                   => $idle_timeout,
}

package { 'socat': ensure => present }

#TODO: PUT this configuration stanza into nova class
nova_config {
  'DEFAULT/use_cow_images':               value => hiera('use_cow_images');
  'keystone_authtoken/memcached_servers': value => join(any2array($memcached_servers), ',');
}

if $primary_controller {

  $haproxy_stats_url = "http://${management_vip}:10000/;csv"

  haproxy_backend_status { 'nova-api' :
    name    => 'nova-api-2',
    url     => $haproxy_stats_url,
  }

  Openstack::Ha::Haproxy_service <| |> -> Haproxy_backend_status <| |>

  Class['nova::api'] -> Haproxy_backend_status['nova-api']

  exec { 'create-m1.micro-flavor' :
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    environment => [
      "OS_TENANT_NAME=${keystone_tenant}",
      "OS_USERNAME=${keystone_user}",
      "OS_PASSWORD=${nova_hash['user_password']}",
      "OS_AUTH_URL=http://${service_endpoint}:5000/v2.0/",
      'OS_ENDPOINT_TYPE=internalURL',
      "OS_REGION_NAME=${region}",
      "NOVA_ENDPOINT_TYPE=internalURL",
    ],
    command   => 'bash -c "nova flavor-create --is-public true m1.micro auto 64 0 1"',
    unless    => 'bash -c "nova flavor-list | grep -q m1.micro"',
    tries     => 10,
    try_sleep => 2,
    require   => Class['nova'],
  }

  Haproxy_backend_status <| |>    -> Exec<| title == 'create-m1.micro-flavor' |>

  if ! $use_neutron {
    nova_floating_range { $floating_ips_range:
      ensure          => 'present',
      pool            => 'nova',
      username        => $access_hash[user],
      api_key         => $access_hash[password],
      auth_method     => 'password',
      auth_url        => "http://${service_endpoint}:5000/v2.0/",
      authtenant_name => $access_hash[tenant],
      api_retries     => 10,
    }
    Haproxy_backend_status['nova-api'] -> Nova_floating_range <| |>
  }
}

nova_config {
  'DEFAULT/teardown_unused_network_gateway': value => 'True'
}

if $sahara_hash['enabled'] {
  $nova_scheduler_default_filters = [ 'DifferentHostFilter' ]
} else {
  $nova_scheduler_default_filters = []
}

class { '::nova::scheduler::filter':
  cpu_allocation_ratio       => pick($nova_hash['cpu_allocation_ratio'], '8.0'),
  disk_allocation_ratio      => pick($nova_hash['disk_allocation_ratio'], '1.0'),
  ram_allocation_ratio       => pick($nova_hash['ram_allocation_ratio'], '1.0'),
  scheduler_host_subset_size => pick($nova_hash['scheduler_host_subset_size'], '30'),
  scheduler_default_filters  => concat($nova_scheduler_default_filters, pick($nova_config_hash['default_filters'], [ 'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter', 'ComputeCapabilitiesFilter', 'ImagePropertiesFilter', 'ServerGroupAntiAffinityFilter', 'ServerGroupAffinityFilter' ]))
}

# From logasy filter.pp
nova_config {
  'DEFAULT/ram_weight_multiplier':        value => '1.0'
}

