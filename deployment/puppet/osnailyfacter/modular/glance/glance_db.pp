notice('MODULAR: glance_db.pp')

$glance_hash    = hiera_hash('glance', {})
$mysql_hash     = hiera_hash('mysql', {})
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($glance_hash['db_user'], 'glance')
$db_name     = pick($glance_hash['db_name'], 'glance')
$db_password = pick($glance_hash['db_password'], $mysql_root_password)

$db_host          = pick($glance_hash['db_host'], $database_vip, 'localhost')
$db_create        = pick($glance_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($glance_hash['root_user'], $mysql_root_user)
$db_root_password = pick($glance_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ hiera('node_name'), 'localhost', '127.0.0.1', '%' ]

validate_string($mysql_root_user)

if $db_create {

  class { 'glance::db::mysql':
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

  Class['osnailyfacter::mysql_access'] -> Class['glance::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
