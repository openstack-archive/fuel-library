$use_neutron    = hiera('use_neutron', false)
$neutron_hash   = hiera_hash('neutron_config', {})
$mysql_hash     = hiera_hash('mysql', {})
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($neutron_hash['db_user'], 'neutron')
$db_name     = pick($neutron_hash['db_name'], 'neutron')
$db_password = pick($neutron_hash['passwd'], $mysql_root_password)

$db_host          = pick($neutron_hash['db_host'], $database_vip, $management_vip, 'localhost')
$db_create        = pick($neutron_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($neutron_hash['root_user'], $mysql_root_user)
$db_root_password = pick($neutron_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

validate_string($mysql_root_user)

if $use_neutron and $db_create {

  class { 'neutron::db::mysql':
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

  Class['osnailyfacter::mysql_access'] -> Class['neutron::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
