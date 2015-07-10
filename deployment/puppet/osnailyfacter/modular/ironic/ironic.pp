notice('MODULAR: ironic.pp')

$debug          = hiera('debug', false)
$verbose        = hiera('verbose', true)
$rabbit_hash    = hiera_hash('rabbit_hash',{})
$amqp_hosts     = hiera('amqp_hosts')
$nodes_hash     = hiera('nodes')
$ironic_hash    = hiera_hash('ironic', {})
$mysql_hash     = hiera_hash('mysql', {})
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)
$roles          = node_roles($nodes_hash, hiera('uid'))

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_type     = 'mysql'
$db_user     = pick($ironic_hash['db_user'], 'ironic')
$db_name     = pick($ironic_hash['db_name'], 'ironic')
$db_password = pick($ironic_hash['db_password'], $mysql_root_password)

$db_host          = pick($ironic_hash['db_host'], $database_vip, $management_vip, 'localhost')
$db_create        = pick($ironic_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($ironic_hash['root_user'], $mysql_root_user)
$db_root_password = pick($ironic_hash['root_password'], $mysql_root_password)

$rabbit_password     = $rabbit_hash['password']
$rabbit_user         = $rabbit_hash['user']
$rabbit_hosts        = split($amqp_hosts, ',')
$rabbit_virtual_host = '/'


#################################################################

if $ironic_hash['enabled'] {

  $database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

  class { '::ironic':
    debug               => $debug,
    verbose             => $verbose,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    database_connection => $database_connection,
  }

  class {'::ironic::client':}
}
