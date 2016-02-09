notice('MODULAR: openstack-controller.pp')

$network_scheme = hiera_hash('network_scheme', {})
$override_configuration = hiera_hash('configuration', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$nova_rate_limits             = hiera('nova_rate_limits')
$primary_controller           = hiera('primary_controller')
$use_neutron                  = hiera('use_neutron', false)
$nova_report_interval         = hiera('nova_report_interval')
$nova_service_down_time       = hiera('nova_service_down_time')
$use_syslog                   = hiera('use_syslog', true)
$use_stderr                   = hiera('use_stderr', false)
$syslog_log_facility_nova     = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$management_vip               = hiera('management_vip')
$sahara_hash                  = hiera_hash('sahara', {})
$storage_hash                 = hiera_hash('storage', {})
$nova_hash                    = hiera_hash('nova', {})
$nova_config_hash             = hiera_hash('nova_config', {})
$api_bind_address             = get_network_role_property('nova/api', 'ipaddr')
$rabbit_hash                  = hiera_hash('rabbit_hash', {})
$service_endpoint             = hiera('service_endpoint')
$ssl_hash                     = hiera_hash('use_ssl', {})

$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [$nova_hash['auth_protocol'], 'http'])
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
$admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', [$nova_hash['auth_protocol'], 'http'])
$admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

$keystone_auth_uri     = "${internal_auth_protocol}://${internal_auth_address}:5000/"
$keystone_identity_uri = "${admin_auth_protocol}://${admin_auth_address}:35357/"
$keystone_ec2_url      = "${keystone_auth_uri}v2.0/ec2tokens"

$glance_protocol              = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
$glance_endpoint              = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [hiera('glance_endpoint', ''), $management_vip])
$glance_ssl                   = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)
if $glance_ssl {
  $glance_api_servers = "${glance_protocol}://${glance_endpoint}:9292"
} else {
  $glance_api_servers = hiera('glance_api_servers', "${management_vip}:9292")
}

$keystone_user                = pick($nova_hash['user'], 'nova')
$keystone_tenant              = pick($nova_hash['tenant'], 'services')
$region                       = hiera('region', 'RegionOne')
$workers_max                  = hiera('workers_max', 16)
$service_workers              = pick($nova_hash['workers'],
                                      min(max($::processorcount, 2), $workers_max))
$ironic_hash                  = hiera_hash('ironic', {})

$memcached_server             = hiera('memcached_addresses')
$memcached_port               = hiera('memcache_server_port', '11211')
$openstack_controller_hash    = hiera_hash('openstack_controller', {})

$external_lb                  = hiera('external_lb', false)

if $use_neutron {
  $neutron_config            = hiera_hash('quantum_settings')
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $default_floating_net      = pick($neutron_config['default_floating_net'], 'net04_ext')
} else {
  $floating_ips_range   = hiera('floating_network_range')
  $default_floating_net = 'nova'
}

$db_type     = 'mysql'
$db_host     = pick($nova_hash['db_host'], hiera('database_vip'))
$db_user     = pick($nova_hash['db_user'], 'nova')
$db_password = $nova_hash['db_password']
$db_name     = pick($nova_hash['db_name'], 'nova')
# TODO(aschultz): update this class to accept a connection string rather
# than use host/user/pass/dbname/type
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

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')

$enabled_apis = 'ec2,osapi_compute,osapi_volume'

if hiera('nova_quota') {
  $nova_quota_driver = 'nova.quota.DbQuotaDriver'
} else {
  $nova_quota_driver = 'nova.quota.NoopQuotaDriver'
}

if hiera('use_vcenter', false) or hiera('libvirt_type') == 'vcenter' {
  $multi_host = false
} else {
  $multi_host = true
}

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

$memcached_addresses =  suffix($memcached_server, inline_template(":<%= @memcached_port %>"))

# we can't use pick for this because pick blows up on []
if $nova_hash['notification_driver'] {
  $nova_notification_driver = $nova_hash['notification_driver']
} else {
  $nova_notification_driver = []
}

# From legacy ceilometer notifications for nova
if ($ceilometer_notification_driver) {
  $notify_on_state_change = 'vm_and_task_state'
  $notification_driver = concat([$ceilometer_notification_driver], $nova_notification_driver)
} else {
  $notification_driver = $nova_notification_driver
}

# FIXME(bogdando) replace queue_provider for rpc_backend once all modules synced with upstream
$rpc_backend   = 'nova.openstack.common.rpc.impl_kombu'
$amqp_hosts    = hiera('amqp_hosts','')
$amqp_user     = $rabbit_hash['user']
$amqp_password = $rabbit_hash['password']
$verbose       = pick($openstack_controller_hash['verbose'], true)
$debug         = pick($openstack_controller_hash['debug'], hiera('debug', true))
$auto_assign_floating_ip = hiera('auto_assign_floating_ip', false)

$fping_path = $::osfamily ? {
  'Debian' => '/usr/bin/fping',
  'RedHat' => '/usr/sbin/fping',
  default => fail('Unsupported Operating System.'),
}
#################################################################

class { 'nova':
  install_utilities      => false,
  database_connection    => $db_connection,
  rpc_backend            => $rpc_backend,
  #FIXME(bogdando) we have to split amqp_hosts until all modules synced
  rabbit_hosts           => split($amqp_hosts, ','),
  rabbit_userid          => $amqp_user,
  rabbit_password        => $amqp_password,
  kombu_reconnect_delay  => '5.0',
  image_service          => 'nova.image.glance.GlanceImageService',
  glance_api_servers     => $glance_api_servers,
  verbose                => $verbose,
  debug                  => $debug,
  log_facility           => $syslog_log_facility_nova,
  use_syslog             => $use_syslog,
  use_stderr             => $use_stderr,
  database_idle_timeout  => $idle_timeout,
  report_interval        => $nova_report_interval,
  service_down_time      => $nova_service_down_time,
  notify_on_state_change => $notify_on_state_change,
  notify_api_faults      => $nova_hash['notify_api_faults'],
  notification_driver    => $notification_driver,
  memcached_servers      => $memcached_addresses,
  cinder_catalog_info    => pick($nova_hash['cinder_catalog_info'], 'volume:cinder:internalURL'),
  database_max_pool_size => $max_pool_size,
  database_max_retries   => $max_retries,
  database_max_overflow  => $max_overflow,
}

# TODO(aschultz): this is being removed in M, do we need it?
if $use_syslog {
  nova_config {
    'DEFAULT/use_syslog_rfc_format':  value => true;
  }
}

class { '::nova::quota':
  quota_instances                       => pick($nova_hash['quota_instances'], 100),
  quota_cores                           => pick($nova_hash['quota_cores'], 100),
  quota_volumes                         => pick($nova_hash['quota_volumes'], 100),
  quota_gigabytes                       => pick($nova_hash['quota_gigabytes'], 1000),
  quota_floating_ips                    => pick($nova_hash['quota_floating_ips'], 100),
  quota_metadata_items                  => pick($nova_hash['quota_metadata_items'], 1024),
  quota_max_injected_files              => pick($nova_hash['quota_max_injected_files'], 50),
  quota_max_injected_file_content_bytes => pick($nova_hash['quota_max_injected_file_content_bytes'], 102400),
  quota_injected_file_path_length       => pick($nova_hash['quota_injected_file_path_length'], 4096),
  quota_security_groups                 => pick($nova_hash['quota_security_groups'], 10),
  quota_key_pairs                       => pick($nova_hash['quota_key_pairs'], 10),
  quota_driver                          => $nova_quota_driver
}

if ! $use_neutron {
  # Configure nova-network
  if $multi_host {
    nova_config { 'DEFAULT/multi_host': value => 'True' }
    $_enabled_apis = $enabled_apis
  } else {
    $_enabled_apis = "${enabled_apis},metadata"
  }
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
(POST, %(*/servers), ^/servers,  #{@post_servers_limit} , DAY);(PUT, %(*) , .*,  #{@put_limit}\
, MINUTE);(GET, %(*changes-since*), .*changes-since.*, #{@get_limit}, MINUTE);(DELETE, %(*),\
.*, #{@delete_limit} , MINUTE)" %>')
#  notice("will apply following limits: ${nova_rate_limits_string}")
# Configure nova-api
class { '::nova::api':
  enabled                              => true,
  api_bind_address                     => $api_bind_address,
  admin_user                           => $keystone_user,
  admin_password                       => $nova_hash['user_password'],
  admin_tenant_name                    => pick($nova_hash['admin_tenant_name'], $keystone_tenant),
  identity_uri                         => $keystone_identity_uri,
  auth_uri                             => $keystone_auth_uri,
  auth_version                         => pick($nova_hash['auth_version'], false),
  enabled_apis                         => $_enabled_apis,
  ratelimits                           => $nova_rate_limits_string,
  neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
  osapi_compute_workers                => $service_workers,
  metadata_workers                     => $service_workers,
  sync_db                              => $primary_controller,
  fping_path                           => $fping_path,
  api_paste_config                     => '/etc/nova/api-paste.ini',
  default_floating_pool                => $default_floating_pool,
  require                              => Package['nova-common'],
}

# From legacy init.pp
if !defined(Package[$pymemcache_package_name]) {
  package { $pymemcache_package_name:
    ensure => present,
  } ->
  Nova::Generic_service <| title == 'api' |>
}

nova_config {
  'DEFAULT/allow_resize_to_same_host':  value => pick($nova_hash['allow_resize_to_same_host'], true);
  'keystone_authtoken/signing_dir':     value => '/tmp/keystone-signing-nova';
  'keystone_authtoken/signing_dirname': value => '/tmp/keystone-signing-nova';
}

nova_paste_api_ini {
  'filter:authtoken/signing_dir':       ensure => absent;
  'filter:authtoken/signing_dirname':   ensure => absent;
}

class {'::nova::conductor':
  enabled   => true,
  workers   => $service_workers,
  use_local => pick($nova_hash['use_local'], false),
}

if $auto_assign_floating_ip {
  nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
}

# a bunch of nova services that require no configuration
class { [
  '::nova::scheduler',
  '::nova::objectstore',
  '::nova::cert',
  '::nova::consoleauth',
]:
  enabled => true,
}

# TODO(aschultz): when the openstacklib & nova modules have been updated
# with a version that supports os_package_type, remove this block
# See LP#1530912
if !$::os_package_type or $::os_package_type == 'debian' {
  $nova_vncproxy_package = 'nova-consoleproxy'
  Package<| title == 'nova-vncproxy' |> {
    name => 'nova-consoleproxy'
  }
} else {
  $nova_vnc_proxypackage = 'nova-vncproxy'
}
tweaks::ubuntu_service_override { 'nova-vncproxy':
  package_name => $nova_vncproxy_package,
}

class { 'nova::vncproxy':
  enabled => true,
  host    => $api_bind_address,
}

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'nova-cert':
    package_name => 'nova-cert',
  }
  tweaks::ubuntu_service_override { 'nova-conductor':
    package_name => 'nova-conductor',
  }
  tweaks::ubuntu_service_override { 'nova-consoleproxy':
    package_name => 'nova-consoleproxy',
  }
  tweaks::ubuntu_service_override { 'nova-api':
    package_name => 'nova-api',
  }
  tweaks::ubuntu_service_override { 'nova-objectstore':
    package_name => 'nova-objectstore',
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
  'DEFAULT/use_cow_images': value => hiera('use_cow_images');
  'DEFAULT/force_raw_images': value => $nova_hash['force_raw_images'],
}

if $primary_controller {

  $haproxy_stats_url = "http://${management_vip}:10000/;csv"

  $nova_endpoint           = hiera('nova_endpoint', $management_vip)
  $nova_internal_protocol  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
  $nova_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])
  $nova_url                = "${nova_internal_protocol}://${nova_internal_endpoint}:8774"

  $lb_defaults = { 'provider' => 'haproxy', 'url' => $haproxy_stats_url }

  if $external_lb {
    $lb_backend_provider = 'http'
    $lb_url = $nova_url
  }

  $lb_hash = {
    'nova-api' => {
      name     => 'nova-api',
      provider => $lb_backend_provider,
      url      => $lb_url
    }
  }

  ::osnailyfacter::wait_for_backend {'nova-api':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }


  Openstack::Ha::Haproxy_service <| |> -> Haproxy_backend_status <| |>

  Class['nova::api'] -> ::Osnailyfacter::Wait_for_backend['nova-api']
  ::Osnailyfacter::Wait_for_backend['nova-api'] -> Exec<| title == 'create-m1.micro-flavor' |>
  ::Osnailyfacter::Wait_for_backend['nova-api'] -> Nova_floating <| |>

  Class['::osnailyfacter::wait_for_keystone_backends'] ->  Exec<| title == 'create-m1.micro-flavor' |>
  Class['::osnailyfacter::wait_for_keystone_backends'] ->  Nova_floating <| |>

  class {"::osnailyfacter::wait_for_keystone_backends":}
  exec { 'create-m1.micro-flavor' :
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    environment => [
      "OS_TENANT_NAME=${keystone_tenant}",
      "OS_PROJECT_NAME=${keystone_tenant}",
      "OS_USERNAME=${keystone_user}",
      "OS_PASSWORD=${nova_hash['user_password']}",
      "OS_AUTH_URL=${internal_auth_protocol}://${internal_auth_address}:5000/v2.0/",
      'OS_ENDPOINT_TYPE=internalURL',
      "OS_REGION_NAME=${region}",
      "NOVA_ENDPOINT_TYPE=internalURL",
    ],
    command   => 'bash -c "nova flavor-create --is-public true m1.micro auto 64 0 1"',
    #FIXME(mattymo): Upstream bug PUP-2299 for retries in unless/onlyif
    # Retry nova-flavor list until it exits 0, then exit with grep status,
    # finally exit 1 if tries exceeded
    # lint:ignore:single_quote_string_with_variables
    unless    => 'bash -c \'for tries in {1..10}; do
                    nova flavor-list | grep m1.micro;
                    status=("${PIPESTATUS[@]}");
                    (( ! status[0] )) && exit "${status[1]}";
                    sleep 2;
                  done; exit 1\'',
    # lint:endignore
    tries     => 10,
    try_sleep => 2,
    require   => Class['nova'],
  }


  if ! $use_neutron {
    nova_floating { $floating_ips_range:
      ensure          => 'present',
      pool            => 'nova',
    }
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

if $ironic_hash['enabled'] {
  $scheduler_host_manager = 'nova.scheduler.ironic_host_manager.IronicHostManager'
}

class { '::nova::scheduler::filter':
  cpu_allocation_ratio       => pick($nova_hash['cpu_allocation_ratio'], '8.0'),
  disk_allocation_ratio      => pick($nova_hash['disk_allocation_ratio'], '1.0'),
  ram_allocation_ratio       => pick($nova_hash['ram_allocation_ratio'], '1.0'),
  scheduler_host_subset_size => pick($nova_hash['scheduler_host_subset_size'], '30'),
  scheduler_default_filters  => concat($nova_scheduler_default_filters, pick($nova_config_hash['default_filters'], [ 'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter', 'ComputeCapabilitiesFilter', 'ImagePropertiesFilter', 'ServerGroupAntiAffinityFilter', 'ServerGroupAffinityFilter' ])),
  scheduler_host_manager     => $scheduler_host_manager,
}

# From logasy filter.pp
nova_config {
  'DEFAULT/ram_weight_multiplier':        value => '1.0'
}

# override nova options
override_resources { 'nova_config':
  data => $override_configuration['nova_config']
}

# override nova-api options
override_resources { 'nova_paste_api_ini':
  data => $override_configuration['nova_paste_api_ini']
}

if $storage_hash['volumes_ceph'] {
  package { 'open-iscsi':
    ensure => present,
  }
}
