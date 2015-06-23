$cinder_hash    = hiera_hash('cinder', {})
$mysql_hash     = hiera_hash('mysql', {})
$database_vip   = hiera('database_vip', undef)

$mysql_db_host       = pick($mysql_hash, 'db_host', $database_vip)
$mysql_root_user     = pick($mysql_hash, 'root_user', 'root')
$mysql_root_password = pick($mysql_hash, 'root_password')
$mysql_db_create     = pick($mysql_hash, 'db_create', true)

$db_user     = pick($cinder_hash, 'db_user', 'cinder')
$db_name     = pick($cinder_hash, 'db_name', 'cinder')
$db_password = pick($cinder_hash, 'db_password')

$db_host       = pick($cinder_hash, 'db_host', $mysql_db_host)
$db_create     = pick($cinder_hash, 'db_create', $mysql_db_create)
$root_user     = pick($cinder_hash, 'root_user', $mysql_root_user)
$root_password = pick($cinder_hash, 'root_password', $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $db_create {

  # Create the Keystone db
  class { 'cinder::db::mysql':
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

    Class['osnailyfacter::mysql_access'] -> Class['cinder::db::mysql']

  }
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
