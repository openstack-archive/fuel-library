$glance_hash    = hiera_hash('glance', {})
$mysql_hash     = hiera_hash('mysql', {})
$database_vip   = hiera('database_vip', undef)

$mysql_db_host       = fetch($mysql_hash, 'db_host', $database_vip)
$mysql_root_user     = fetch($mysql_hash, 'root_user', 'root')
$mysql_root_password = fetch($mysql_hash, 'root_password')
$mysql_db_create     = fetch($mysql_hash, 'db_create', true)

$db_user     = fetch($glance_hash, 'db_user', 'glance')
$db_name     = fetch($glance_hash, 'db_name', 'glance')
$db_password = fetch($glance_hash, 'db_password')

$db_host       = fetch($glance_hash, 'db_host', $mysql_db_host)
$db_create     = fetch($glance_hash, 'db_create', $mysql_db_create)
$root_user     = fetch($glance_hash, 'root_user', $mysql_root_user)
$root_password = fetch($glance_hash, 'root_password', $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $db_create {

  # Create the Keystone db
  class { 'glance::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  if $db_host and $root_user and $root_password {

    # Work with remote database host
    class { 'osnailyfacter::mysql_access' :
      db_user     => $root_user,
      db_password => $root_password,
      db_host     => $db_host,
    }

    Class['osnailyfacter::mysql_access'] -> Class['glance::db::mysql']

  }
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
