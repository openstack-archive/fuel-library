notice('MODULAR: aodh.pp')

$debug = true
$verbose = true
# new: oslo_messaging_notifications/topics = 'notifications'
$notification_topics = 'notifications'

$rpc_backend = 'rabbit'

# new: oslo_messaging_rabbit/rabbit_ha_queues = 
$rabbit_ha_queues = hiera('rabbit_ha_queues')

$rabbit_hash = hiera_hash('rabbit_hash', {})
$rabbit_userid = $rabbit_hash['user']
$rabbit_password = $rabbit_hash['password']

$amqp_port = hiera('amqp_port')
$amqp_hosts = hiera('amqp_hosts')
$rabbit_port = $amqp_port
$rabbit_hosts = split($amqp_hosts, ',')
$rabbit_virtual_host = '/'
## $rabbit_use_ssl = false

prepare_network_config(hiera_hash('network_scheme', {}))

$ssl = false

$aodh_hash            = hiera_hash('aodh_hash', {'db_password' => 'aodh'})
$aodh_user_name       = pick($aodh_hash['user_name'], 'aodh')
$aodh_user_password   = pick($aodh_hash['user_password'], 'aodh')
$service_name         = pick($aodh_hash['service_name'], 'aodh')
$region               = pick($aodh_hash['region'], hiera('region', 'RegionOne'))
$tenant               = pick($aodh_hash['tenant'], 'services')

$database_vip = hiera('database_vip')

$db_type          = 'mysql' # pick($aodh_hash['db']['type'], 'mysql')
$db_user          = pick($aodh_hash['db']['user_name'], 'aodh')
$db_name          = pick($aodh_hash['db']['database'], 'aodh')
$db_password      = pick($aodh_hash['db']['user_password'])
$db_host          = pick($aodh_hash['db']['db_host'], $database_vip)
$db_collate       = pick($aodh_hash['db']['collate'], 'utf8_general_ci')
$db_charset       = pick($aodh_hash['db']['charset'], 'utf8')
$db_allowed_hosts = pick($aodh_hash['db']['allowed_hosts'], '%')
if $::os_package_type == 'debian' {
    $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
  } else {
    $extra_params = { 'charset' => 'utf8' }
}
$database_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

$public_vip = hiera('public_vip')
$public_ssl_hash = hiera('public_ssl')
$public_address = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}

$bind_port = '8042'
$public_url = "${public_protocol}://${public_address}:${bind_port}"
$admin_address = hiera('management_vip')
$admin_url = "${public_protocol}://${admin_address}:${bind_port}"
$bind_host = $admin_address

$ssl_hash = hiera_hash('use_ssl', {})
$public_cert = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

$memcache_address = get_network_role_property('mgmt/memcache', 'ipaddr')
$memcache_servers = "${memcache_address}:11211"

$internal_auth_protocol   = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_address    = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$admin_address])
$keystone_auth_uri        = "${internal_auth_protocol}://${internal_auth_address}:5000/"
$keystone_identity_uri    = "${internal_auth_protocol}://${internal_auth_address}:35357/"

$ha_mode = pick($ceilometer_hash['ha_mode'], true)

#################################################################

class { '::aodh':
  ensure_package       => 'present',
  debug                => $debug,
  verbose              => $verbose,
  notification_topics  => $notification_topics,
  rpc_backend          => $rpc_backend,
  rabbit_userid        => $rabbit_userid,
  rabbit_password      => $rabbit_password,
  rabbit_hosts         => $rabbit_hosts,
  rabbit_port          => $rabbit_port,
  rabbit_virtual_host  => $rabbit_virtual_host,
  rabbit_ha_queues     => $rabbit_ha_queues,
  database_connection  => $database_connection,
}

class { 'aodh::auth':
  auth_url           => $keystone_auth_uri, #$internal_url,  # the keystone public endpoint
  auth_user          => $aodh_user_name,
  auth_password      => $aodh_user_password,
  auth_region        => $region,
  auth_tenant_name   => $tenant,
  auth_cacert        => $public_cert,
  auth_endpoint_type => 'internalURL',
}

aodh_config { 'oslo_policy/policy_file': value => '/etc/aodh/policy.json'; }
aodh_config { 'notification/store_events': value => true; }
aodh_config { 'api/pecan_debug': value => false; }

class { 'aodh::db::sync':
  user => $db_user,
}

Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['aodh::keystone::auth']

class {'::osnailyfacter::wait_for_keystone_backends':}

# configure Aodh "user", "service" and "endpoint" _in Keystone_.
class { 'aodh::keystone::auth':
  auth_name      => $aodh_user_name,
  password       => $aodh_user_password,
  service_type   => 'alarming',
  service_name   => $service_name,
  region         => $region,
  tenant         => $tenant,
  public_url     => $public_url,
  internal_url   => $admin_url,
  admin_url      => $admin_url,
}
aodh_config {
  'keystone_authtoken/memcache_servers': value => $memcache_servers;
  'keystone_authtoken/signing_dir'     : value => '/tmp/keystone-signing-aodh';
}

class { '::aodh::api':
  enabled               => true,
  manage_service        => true,
  package_ensure        => 'present',
  keystone_user         => $aodh_user_name,
  keystone_password     => $aodh_user_password,
  keystone_tenant       => $tenant,
  keystone_auth_uri     => $keystone_auth_uri,
  keystone_identity_uri => $keystone_identity_uri,
  host                  => $bind_host,
  port                  => $bind_port,
}

class { '::aodh::evaluator':
  manage_service   => true,
  enabled          => true,
  package_ensure   => 'present',
}

class { '::aodh::notifier':
  manage_service => true,
  enabled        => true,
  package_ensure => 'present',
}

class { '::aodh::listener':
  manage_service => true,
  enabled        => true,
  package_ensure => 'present',
}

class { '::aodh::client':
  ensure => 'present'
}

if $ha_mode {
  include aodh_ha::alarm::evaluator

  Package[$::aodh::params::common_package_name] -> Class['aodh_ha::alarm::evaluator']
  Package[$::aodh::params::evaluator_package_name] -> Class['aodh_ha::alarm::evaluator']
}

