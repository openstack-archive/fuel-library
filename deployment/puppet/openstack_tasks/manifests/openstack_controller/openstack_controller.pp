# Copyright (C) 2015-2016 Mirantis
# Copyright (C) 2016 AT&T

class openstack_tasks::openstack_controller::openstack_controller {

  notice('MODULAR: openstack_controller/openstack_controller.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $primary_controller           = hiera('primary_controller')
  $use_syslog                   = hiera('use_syslog', true)
  $use_stderr                   = hiera('use_stderr', false)
  $syslog_log_facility_nova     = hiera('syslog_log_facility_nova','LOG_LOCAL6')
  $management_vip               = hiera('management_vip')
  $ceilometer_hash              = hiera_hash('ceilometer', {})
  $sahara_hash                  = hiera_hash('sahara', {})
  $storage_hash                 = hiera_hash('storage', {})
  $nova_hash                    = hiera_hash('nova', {})
  $nova_rate_limits             = $nova_hash['nova_rate_limits']
  $nova_config_hash             = hiera_hash('nova_config', {})
  $nova_report_interval         = hiera('nova_report_interval', '60')
  $nova_service_down_time       = hiera('nova_service_down_time', '180')
  $api_bind_address             = get_network_role_property('nova/api', 'ipaddr')
  $rabbit_hash                  = hiera_hash('rabbit', {})
  $service_endpoint             = hiera('service_endpoint')
  $ssl_hash                     = hiera_hash('use_ssl', {})
  $node_hash                    = hiera_hash('node_hash', {})
  $sahara_enabled               = pick($sahara_hash['enabled'], false)
  $kombu_compression            = hiera('kombu_compression', $::os_service_default)

  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [$nova_hash['auth_protocol'], 'http'])
  $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', [$nova_hash['auth_protocol'], 'http'])
  $admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

  $keystone_auth_uri = "${internal_auth_protocol}://${internal_auth_address}:5000/"
  $keystone_auth_url = "${admin_auth_protocol}://${admin_auth_address}:35357/"
  $keystone_ec2_url  = "${keystone_auth_uri}v2.0/ec2tokens"

  # get glance api servers list
  $glance_endpoint_default      = hiera('glance_endpoint', $management_vip)
  $glance_protocol              = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_endpoint              = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', $glance_endpoint_default)
  $glance_api_servers           = hiera('glance_api_servers', "${glance_protocol}://${glance_endpoint}:9292")

  $keystone_user                = pick($nova_hash['user'], 'nova')
  $keystone_tenant              = pick($nova_hash['tenant'], 'services')
  $region_name                  = hiera('region', 'RegionOne')
  $workers_max                  = hiera('workers_max', $::os_workers)
  $service_workers              = pick($nova_hash['workers'],
                                        min(max($::processorcount, 2), $workers_max))
  $compute_nodes                = get_nodes_hash_by_roles($network_metadata, ['compute'])
  $huge_pages_nodes             = filter_nodes_with_enabled_option($compute_nodes, 'nova_hugepages_enabled')
  $cpu_pinning_nodes            = filter_nodes_with_enabled_option($compute_nodes, 'nova_cpu_pinning_enabled')

  $ironic_hash                  = hiera_hash('ironic', {})

  $openstack_controller_hash    = hiera_hash('openstack_controller', {})

  $external_lb                  = hiera('external_lb', false)

  $neutron_config                = hiera_hash('quantum_settings')
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $default_floating_net          = pick($neutron_config['default_floating_net'], 'net04_ext')
  $pci_vendor_devs               = pick($neutron_config['supported_pci_vendor_devs'], false)

  $repo_setup              = hiera_hash('repo_setup', {})
  $repo_type               = pick_default($repo_setup['repo_type'], '')
  # Boolean value for further usage
  if $pci_vendor_devs {
    $sriov_enabled = true
  } else {
    $sriov_enabled = false
  }

  if size($huge_pages_nodes) > 0 {
    $use_huge_pages = true
  } else {
    $use_huge_pages = false
  }

  if size($cpu_pinning_nodes) > 0 {
    $enable_cpu_pinning = true
  } else {
    $enable_cpu_pinning = false
  }

  $db_type     = pick($nova_hash['db_type'], 'mysql+pymysql')
  $db_host     = pick($nova_hash['db_host'], hiera('database_vip'))
  $db_user     = pick($nova_hash['db_user'], 'nova')
  $db_password = $nova_hash['db_password']
  $db_name     = pick($nova_hash['db_name'], 'nova')
  $api_db_user     = pick($nova_hash['api_db_user'], 'nova_api')
  $api_db_password = pick($nova_hash['api_db_password'], $nova_hash['db_password'])
  $api_db_name     = pick($nova_hash['api_db_name'], 'nova_api')
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
  $api_db_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $api_db_name,
    'username' => $api_db_user,
    'password' => $api_db_password,
    'extra'    => $extra_params
  })

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

  # SQLAlchemy backend configuration
  $max_pool_size = hiera('max_pool_size', min($::os_workers * 5 + 0, 30 + 0))
  $max_overflow = hiera('max_overflow', min($::os_workers * 5 + 0, 60 + 0))
  $idle_timeout = hiera('idle_timeout', '3600')
  $max_retries = hiera('max_retries', '-1')

  if hiera('nova_quota') {
    $nova_quota_driver = 'nova.quota.DbQuotaDriver'
  } else {
    $nova_quota_driver = 'nova.quota.NoopQuotaDriver'
  }

  $notify_on_state_change = 'vm_and_task_state'

  # From legacy params.pp
  case $::osfamily {
    'RedHat': {
      $pymemcache_package_name = 'python-memcached'
    }
    'Debian': {
      $pymemcache_package_name = 'python-memcache'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
  module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  $memcached_servers = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  $debug         = pick($openstack_controller_hash['debug'], hiera('debug', true))

  $fping_path = $::osfamily ? {
    'Debian' => '/usr/bin/fping',
    'RedHat' => '/usr/sbin/fping',
    default => fail('Unsupported Operating System.'),
  }

  $rabbit_heartbeat_timeout_threshold = pick($nova_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($nova_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

  #################################################################

  class { '::nova':
    database_connection                => $db_connection,
    api_database_connection            => $api_db_connection,
    default_transport_url              => $transport_url,
    image_service                      => 'nova.image.glance.GlanceImageService',
    glance_api_servers                 => $glance_api_servers,
    debug                              => $debug,
    log_facility                       => $syslog_log_facility_nova,
    use_syslog                         => $use_syslog,
    use_stderr                         => $use_stderr,
    database_idle_timeout              => $idle_timeout,
    report_interval                    => $nova_report_interval,
    service_down_time                  => $nova_service_down_time,
    notify_api_faults                  => pick($nova_hash['notify_api_faults'], false),
    notification_driver                => $ceilometer_hash['notification_driver'],
    notify_on_state_change             => $notify_on_state_change,
    cinder_catalog_info                => pick($nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
    database_max_pool_size             => $max_pool_size,
    database_max_retries               => $max_retries,
    database_max_overflow              => $max_overflow,
    kombu_compression                  => $kombu_compression,
    rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
    rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,
    os_region_name                     => $region_name,
    cpu_allocation_ratio               => pick($nova_hash['cpu_allocation_ratio'], '8.0'),
    disk_allocation_ratio              => pick($nova_hash['disk_allocation_ratio'], '1.0'),
    ram_allocation_ratio               => pick($nova_hash['ram_allocation_ratio'], '1.0'),
  }

  # TODO(aschultz): this is being removed in M, do we need it?
  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog_rfc_format':  value => true;
    }
  }

  if pick($nova_hash['use_cache'], true) {
    class { '::nova::cache':
      enabled          => true,
      backend          => 'oslo_cache.memcache_pool',
      memcache_servers => $local_memcached_server,
    }
  } else {
    ensure_packages($pymemcache_package_name)
  }

  class { '::nova::quota':
    quota_instances                   => pick($nova_hash['quota_instances'], 100),
    quota_cores                       => pick($nova_hash['quota_cores'], 100),
    quota_ram                         => pick($nova_hash['quota_ram'], 51200),
    quota_floating_ips                => pick($nova_hash['quota_floating_ips'], 100),
    quota_fixed_ips                   => pick($nova_hash['quota_fixed_ips'], -1),
    quota_metadata_items              => pick($nova_hash['quota_metadata_items'], 1024),
    quota_injected_files              => pick($nova_hash['quota_injected_files'], 50),
    quota_injected_file_content_bytes => pick($nova_hash['quota_injected_file_content_bytes'], 102400),
    quota_injected_file_path_length   => pick($nova_hash['quota_injected_file_path_length'], 4096),
    quota_security_groups             => pick($nova_hash['quota_security_groups'], 10),
    quota_security_group_rules        => pick($nova_hash['quota_security_group_rules'], 20),
    quota_key_pairs                   => pick($nova_hash['quota_key_pairs'], 10),
    quota_server_groups               => pick($nova_hash['quota_server_groups'], 10),
    quota_server_group_members        => pick($nova_hash['quota_server_group_members'], 10),
    reservation_expire                => pick($nova_hash['reservation_expire'], 86400),
    until_refresh                     => pick($nova_hash['until_refresh'], 0),
    max_age                           => pick($nova_hash['max_age'], 0),
    quota_driver                      => $nova_quota_driver
  }

  $default_limits = {
    'POST'         => 10,
    'POST_SERVERS' => 50,
    'PUT'          => 10,
    'GET'          => 3,
    'DELETE'       => 100,
  }

  $merged_limits = merge($default_limits, $nova_rate_limits)
  $post_limit    = $merged_limits['POST']
  $put_limit     = $merged_limits['PUT']
  $get_limit     = $merged_limits['GET']
  $delete_limit  = $merged_limits['DELETE']
  $post_servers_limit = $merged_limits['POST_SERVERS']
  $nova_rate_limits_string = inline_template('<%="(POST, *, .*,  #{@post_limit} , MINUTE);\
  (POST, \"*/servers\", ^/servers,  #{@post_servers_limit} , DAY);(PUT, \"*\" , .*,  #{@put_limit}\
  , MINUTE);(GET, \"*changes-since*\", .*changes-since.*, #{@get_limit}, MINUTE);(DELETE, \"*\",\
  .*, #{@delete_limit} , MINUTE)" %>')

  class { '::nova::keystone::authtoken':
    username          => $keystone_user,
    password          => $nova_hash['user_password'],
    project_name      => pick($nova_hash['admin_tenant_name'], $keystone_tenant),
    auth_url          => $keystone_auth_url,
    auth_uri          => $keystone_auth_uri,
    auth_version      => pick($nova_hash['auth_version'], $::os_service_default),
    memcached_servers => $local_memcached_server,
  }
  if $repo_type == 'uca' {
    class { 'osnailyfacter::apache':
      listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888', '0.0.0.0:5000', '0.0.0.0:35357', '0.0.0.0:8777','0.0.0.0:8042']),
    }

    $ssl = false
    class {'::nova::wsgi::apache_placement':
      ssl       => $ssl,
      priority  => '36',
      bind_host => $bind_host,
      api_port  => 8778,
    }
    class {'::nova::placement':
      password       => $nova_hash['user_password'],
      auth_url       => $keystone_auth_url,
      os_interface   => 'internal',
      project_name   => pick($nova_hash['admin_tenant_name'], $keystone_tenant),
      os_region_name => $region_name
    }
    if $primary_controller {
      include ::nova::cell_v2::simple_setup
    }
  }
  # Configure nova-api
  class { '::nova::api':
    enabled                              => true,
    api_bind_address                     => $api_bind_address,
    metadata_listen                      => $api_bind_address,
    ratelimits                           => $nova_rate_limits_string,
    neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
    osapi_compute_workers                => $service_workers,
    metadata_workers                     => $service_workers,
    sync_db                              => $primary_controller,
    sync_db_api                          => $primary_controller,
    fping_path                           => $fping_path,
    api_paste_config                     => '/etc/nova/api-paste.ini',
    default_floating_pool                => $default_floating_net,
    enable_proxy_headers_parsing         => true,
    allow_resize_to_same_host            => pick($nova_hash['allow_resize_to_same_host'], true),
    require                              => Package['nova-common'],
  }

  # tweak both 'nova-db-sync' and 'nova-db-sync-api' execs
  # TODO(mmalchuk) remove this after LP#1628580 merged
  Exec<| title == 'nova-db-sync' or title == 'nova-db-sync-api' |> {
    tries     => '10',
    try_sleep => '5',
  }

  Package[$pymemcache_package_name] -> Nova::Generic_service <| title == 'api' |>

  class { '::nova::conductor':
    enabled   => true,
    workers   => $service_workers,
    use_local => pick($nova_hash['use_local'], false),
  }

  # a bunch of nova services that require no configuration
  class { [
    '::nova::scheduler',
    '::nova::cert',
    '::nova::consoleauth',
  ]:
    enabled => true,
  }

  class { '::nova::vncproxy':
    enabled => true,
    host    => $api_bind_address,
  }

  include ::nova::params

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-cert':
      package_name => 'nova-cert',
    }
    tweaks::ubuntu_service_override { 'nova-conductor':
      package_name => 'nova-conductor',
    }
    tweaks::ubuntu_service_override { 'nova-novncproxy':
      package_name => $::nova::params::vncproxy_package_name,
    }
    tweaks::ubuntu_service_override { 'nova-api':
      package_name => 'nova-api',
    }
    tweaks::ubuntu_service_override { 'nova-scheduler':
      package_name => 'nova-scheduler',
    }
    tweaks::ubuntu_service_override { 'nova-consoleauth':
      package_name => 'nova-consoleauth',
    }
  }

  #TODO: PUT this configuration stanza into nova class
  nova_config {
    'DEFAULT/use_cow_images':   value => hiera('use_cow_images');
    'DEFAULT/force_raw_images': value => $nova_hash['force_raw_images'];
  }

  nova_config {
    'DEFAULT/teardown_unused_network_gateway': value => 'True'
  }

  $nova_scheduler_default_filters = [ 'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter', 'ComputeCapabilitiesFilter', 'ImagePropertiesFilter', 'ServerGroupAntiAffinityFilter', 'ServerGroupAffinityFilter' ]
  $sriov_filters                  = $sriov_enabled ? { true => [ 'PciPassthroughFilter','AggregateInstanceExtraSpecsFilter' ], default => []}
  $sahara_filters                 = $sahara_enabled ? { true => [ 'DifferentHostFilter' ], default => []}
  $huge_pages_filters             = $use_huge_pages ? { true => [ 'NUMATopologyFilter' ], default => []}
  $cpu_pinning_filters            = $enable_cpu_pinning ? { true => [ 'NUMATopologyFilter', 'AggregateInstanceExtraSpecsFilter' ], default => []}
  $nova_scheduler_filters         = unique(concat(pick($nova_config_hash['default_filters'], $nova_scheduler_default_filters), $sahara_filters, $sriov_filters, $huge_pages_filters, $cpu_pinning_filters))

  if $ironic_hash['enabled'] {
    $scheduler_host_manager  = 'ironic_host_manager'
    $ironic_endpoint_default = hiera('ironic_endpoint', $management_vip)
    $ironic_protocol         = get_ssl_property($ssl_hash, {}, 'ironic', 'internal', 'protocol', 'http')
    $ironic_endpoint         = get_ssl_property($ssl_hash, {}, 'ironic', 'internal', 'hostname', $ironic_endpoint_default)
    class { '::nova::ironic::common':
      admin_username    => pick($ironic_hash['auth_name'],'ironic'),
      admin_password    => pick($ironic_hash['user_password'],'ironic'),
      admin_url         => "${keystone_auth_url}v2.0",
      admin_tenant_name => pick($ironic_hash['tenant'],'services'),
      api_endpoint      => "${ironic_protocol}://${ironic_endpoint}:6385/v1",
    }
  }

  class { '::nova::scheduler::filter':
    scheduler_host_subset_size => pick($nova_hash['scheduler_host_subset_size'], '30'),
    scheduler_default_filters  => $nova_scheduler_filters,
    scheduler_host_manager     => $scheduler_host_manager,
  }

  # From logasy filter.pp
  nova_config {
    'DEFAULT/ram_weight_multiplier':        value => '1.0'
  }


  # TODO (iberezovskiy): In Debian open-iscsi is dependency
  # of os-brick package which is required for cinder.
  # Remove this 'if' once UCA packages are updated as well
  if $::os_package_type == 'ubuntu' and $storage_hash['volumes_ceph'] {
    package { 'open-iscsi':
      ensure => present,
    }
  }

}
