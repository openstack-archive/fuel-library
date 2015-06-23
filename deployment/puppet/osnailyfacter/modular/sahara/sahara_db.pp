$sahara_hash    = hiera_hash('sahara', {})
$mysql_hash     = hiera_hash('mysql', {})
$sahara_enabled = pick($sahara_hash, 'enabled', false)
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)

$mysql_root_password = $mysql_hash['root_password']
$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)

$db_user     = pick($sahara_hash['db_user'], 'sahara')
$db_name     = pick($sahara_hash['db_name'], 'sahara')
$db_password = $sahara_hash['db_password']

$db_host       = pick($sahara_hash['db_host'], $database_vip, $management_vip, 'localhost')
$db_create     = pick($sahara_hash['db_create'], $mysql_db_create)
$root_user     = pick($sahara_hash['root_user'], $mysql_root_user)
$root_password = pick($sahara_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $sahara_enabled and $db_create {

  class { 'sahara::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  class { 'osnailyfacter::mysql_access' :
    db_user     => $root_user,
    db_password => $root_password,
    db_host     => $db_host,
  }

  Class['osnailyfacter::mysql_access'] -> Class['sahara::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class sahara::api {}
include sahara::api
