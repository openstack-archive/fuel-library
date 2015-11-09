notice('MODULAR: keystone.pp')

# Override confguration options
$override_configuration = hiera_hash('configuration', {})
override_resources { 'keystone_config':
  data => $override_configuration['keystone_config']
} ~> Service['httpd']

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$node_name = hiera('node_name')

$keystone_hash         = hiera_hash('keystone', {})
$verbose               = pick($keystone_hash['verbose'], hiera('verbose', true))
$debug                 = pick($keystone_hash['debug'], hiera('debug', false))
$use_neutron           = hiera('use_neutron', false)
$use_syslog            = hiera('use_syslog', true)
$use_stderr            = hiera('use_stderr', false)
$access_hash           = hiera_hash('access',{})
$management_vip        = hiera('management_vip')
$database_vip          = hiera('database_vip')
$public_vip            = hiera('public_vip')
$service_endpoint      = hiera('service_endpoint')
$glance_hash           = hiera_hash('glance', {})
$nova_hash             = hiera_hash('nova', {})
$cinder_hash           = hiera_hash('cinder', {})
$ceilometer_hash       = hiera_hash('ceilometer', {})
$syslog_log_facility   = hiera('syslog_log_facility_keystone')
$rabbit_hash           = hiera_hash('rabbit_hash', {})
$neutron_user_password = hiera('neutron_user_password', false)
$workers_max           = hiera('workers_max', 16)
$service_workers       = pick($keystone_hash['workers'],
                              min(max($::processorcount, 2), $workers_max))
$default_log_levels    = hiera_hash('default_log_levels')
$primary_controller    = hiera('primary_controller')

$db_type     = 'mysql'
$db_host     = pick($keystone_hash['db_host'], $database_vip)
$db_password = $keystone_hash['db_password']
$db_name     = pick($keystone_hash['db_name'], 'keystone')
$db_user     = pick($keystone_hash['db_user'], 'keystone')

$admin_token    = $keystone_hash['admin_token']
$admin_tenant   = $access_hash['tenant']
$admin_email    = $access_hash['email']
$admin_user     = $access_hash['user']
$admin_password = $access_hash['password']
$region         = hiera('region', 'RegionOne')

$public_ssl_hash         = hiera('public_ssl')
$ssl_hash                = hiera_hash('use_ssl', {})

$public_cert             = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

$public_protocol = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
$public_address  = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_vip])
$public_port     = '5000'

$internal_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
$internal_port     = '5000'

$admin_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
$admin_port     = '35357'

$public_cert             = $public_ssl_hash['services']? {
  true    => '/etc/pki/tls/certs/public_haproxy.pem',
  default => undef,
}

$local_address_for_bind = get_network_role_property('keystone/api', 'ipaddr')

$memcache_server_port   = hiera('memcache_server_port', '11211')
$memcache_pool_maxsize = '100'
$memcached_server       = hiera('memcached_addresses')


$token_provider = hiera('token_provider')

$public_url   = "${public_protocol}://${public_address}:${public_port}"
$admin_url    = "${admin_protocol}://${admin_address}:${admin_port}"
$internal_url = "${internal_protocol}://${internal_address}:${internal_port}"

$auth_suffix  = pick($keystone_hash['auth_suffix'], '/')
$auth_url     = "${internal_url}${auth_suffix}"

$revoke_driver = 'keystone.contrib.revoke.backends.sql.Revoke'

$enabled = true
$ssl = false

$vhost_limit_request_field_size = 'LimitRequestFieldSize 81900'

$rabbit_password     = $rabbit_hash['password']
$rabbit_user         = $rabbit_hash['user']
$rabbit_hosts        = split(hiera('amqp_hosts',''), ',')
$rabbit_virtual_host = '/'

$max_pool_size = hiera('max_pool_size')
$max_overflow  = hiera('max_overflow')
$max_retries   = '-1'
$database_idle_timeout  = '3600'

$murano_settings_hash = hiera('murano_settings', {})
if has_key($murano_settings_hash, 'murano_repo_url') {
  $murano_repo_url = $murano_settings_hash['murano_repo_url']
} else {
  $murano_repo_url = 'http://storage.apps.openstack.org'
}

$murano_hash    = hiera_hash('murano_hash', {})
$murano_plugins = pick($murano_hash['plugins'], {})
$murano_glare_plugin = pick($murano_plugins['glance_artifacts_plugin']['enabled'], false)

$external_lb = hiera('external_lb', false)

###############################################################################

####### KEYSTONE ###########
class { 'openstack::keystone':
  verbose                  => $verbose,
  debug                    => $debug,
  default_log_levels       => $default_log_levels,
  db_type                  => $db_type,
  db_host                  => $db_host,
  db_password              => $db_password,
  db_name                  => $db_name,
  db_user                  => $db_user,
  admin_token              => $admin_token,
  public_address           => $public_address,
  public_ssl               => $public_ssl_hash['services'],
  public_hostname          => $public_ssl_hash['hostname'],
  internal_address         => $service_endpoint,
  admin_address            => $admin_address,
  public_bind_host         => $local_address_for_bind,
  admin_bind_host          => $local_address_for_bind,
  primary_controller       => $primary_controller,
  enabled                  => $enabled,
  use_syslog               => $use_syslog,
  use_stderr               => $use_stderr,
  syslog_log_facility      => $syslog_log_facility,
  region                   => $region,
  memcache_servers         => $memcached_server,
  memcache_server_port     => $memcache_server_port,
  memcache_pool_maxsize    => $memcache_pool_maxsize,
  max_retries              => $max_retries,
  max_pool_size            => $max_pool_size,
  max_overflow             => $max_overflow,
  rabbit_password          => $rabbit_password,
  rabbit_userid            => $rabbit_user,
  rabbit_hosts             => $rabbit_hosts,
  rabbit_virtual_host      => $rabbit_virtual_host,
  database_idle_timeout    => $database_idle_timeout,
  revoke_driver            => $revoke_driver,
  public_url               => $public_url,
  admin_url                => $admin_url,
  internal_url             => $internal_url,
  ceilometer               => $ceilometer_hash['enabled'],
  service_workers          => $service_workers,
  token_provider           => $token_provider,
  fernet_src_repository    => '/var/lib/astute/keystone',
}

####### WSGI ###########

# Listen directives with host required for ip_based vhosts
class { 'osnailyfacter::apache':
  listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888', '0.0.0.0:5000', '0.0.0.0:35357']),
}

class { 'keystone::wsgi::apache':
  priority              => '05',
  threads               => 3,
  workers               => min($::processorcount, 6),
  ssl                   => $ssl,
  vhost_custom_fragment => $vhost_limit_request_field_size,
  access_log_format     => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',

  # ports and host should be set for ip_based vhost
  public_port           => $public_port,
  admin_port            => $admin_port,
  bind_host             => $local_address_for_bind,

  wsgi_script_ensure => $::osfamily ? {
    'RedHat'       => 'link',
    default        => 'file',
  },
  wsgi_script_source => $::osfamily ? {
  # TODO: (adidenko) use file from package for Debian, when
  # https://bugs.launchpad.net/fuel/+bug/1476688 is fixed.
  # 'Debian'      => '/usr/share/keystone/wsgi.py',
    'RedHat'       => '/usr/share/keystone/keystone.wsgi',
    default        => undef,
  },
}

include ::tweaks::apache_wrappers

###############################################################################

class { 'keystone::roles::admin':
  admin        => $admin_user,
  password     => $admin_password,
  email        => $admin_email,
  admin_tenant => $admin_tenant,
}

class { 'openstack::auth_file':
  admin_user          => $admin_user,
  admin_password      => $admin_password,
  admin_tenant        => $admin_tenant,
  region_name         => $region,
  auth_url            => $auth_url,
  murano_repo_url     => $murano_repo_url,
  murano_glare_plugin => $murano_glare_plugin,
  cacert              => $public_cert
}

# Get paste.ini source
include keystone::params
$keystone_paste_ini = $::keystone::params::paste_config ? {
  undef   => '/etc/keystone/keystone-paste.ini',
  default => $::keystone::params::paste_config,
}

# Make sure admin token auth middleware is in place
exec { 'add_admin_token_auth_middleware':
  path    => ['/bin', '/usr/bin'],
  command => "sed -i 's/\\( token_auth \\)/\\1admin_token_auth /' $keystone_paste_ini",
  unless  => "fgrep -q ' admin_token_auth' $keystone_paste_ini",
  require => Package['keystone'],
}

#Can't use openrc to create admin user
exec { 'purge_openrc':
  path        => '/bin:/usr/bin:/sbin:/usr/sbin',
  command     => 'rm -f /root/openrc',
  onlyif      => 'test -f /root/openrc',
}

Exec <| title == 'keystone-manage db_sync' |> ~>
Exec <| title == 'purge_openrc' |>

Exec <| title == 'add_admin_token_auth_middleware' |> ->
Exec <| title == 'keystone-manage db_sync' |> ->
Exec <| title == 'purge_openrc' |> ->
Class['keystone::roles::admin'] ->
Class['openstack::auth_file']

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

class {'::osnailyfacter::wait_for_keystone_backends':}

Service['keystone'] -> Class['::osnailyfacter::wait_for_keystone_backends']
Service<| title == 'httpd' |> -> Class['::osnailyfacter::wait_for_keystone_backends']
Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['keystone::roles::admin']
Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['keystone::endpoint']

####### Disable upstart startup on install #######
if ($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'keystone':
    package_name => 'keystone',
  }
}
