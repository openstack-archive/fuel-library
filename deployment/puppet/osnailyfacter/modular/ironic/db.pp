notice('MODULAR: ironic/db.pp')

$node_name = hiera('node_name')

$ironic_hash    = hiera_hash('ironic', {})
$mysql_hash     = hiera_hash('mysql', {})

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($ironic_hash['db_user'], 'ironic')
$db_name     = pick($ironic_hash['db_name'], 'ironic')
$db_password = pick($ironic_hash['db_password'], $mysql_root_password)

$db_host          = pick($ironic_hash['db_host'], $database_vip, 'localhost')
$db_create        = pick($ironic_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($ironic_hash['root_user'], $mysql_root_user)
$db_root_password = pick($ironic_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ $node_name, 'localhost', '127.0.0.1', '%' ]

if $ironic_hash['enabled'] and $db_create {

  include mysql

  class { 'ironic::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  class { 'osnailyfacter::mysql_access':
    db_host     => $db_host,
    db_user     => $db_root_user,
    db_password => $db_root_password,
  }

  Class['mysql'] ->
    Class['osnailyfacter::mysql_access'] ->
      Class['ironic::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
