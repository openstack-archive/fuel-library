$neutron_config = hiera_hash('neutron_config', {})
$mysql_hash     = hiera_hash('mysql', {})
$use_neutron    = hiera('use_neutron', false)
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_root_password = $mysql_hash['root_password']
$mysql_db_create     = pick($mysql_hash['db_create'], true)

$neutron_database_config = pick($neutron_config['database'], {})

$db_user     = pick($neutron_database_config['db_user'], 'neutron')
$db_name     = pick($neutron_database_config['db_name'], 'neutron')
$db_password = $neutron_database_config['passwd']

$db_host       = pick($neutron_database_config['db_host'], $database_vip, $management_vip, 'localhost')
$db_create     = pick($neutron_database_config['db_create'], $mysql_db_create)
$root_user     = pick($neutron_database_config['root_user'], $mysql_root_user)
$root_password = pick($neutron_database_config['root_password'], $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $use_neutron and $db_create {

  class { 'neutron::db::mysql':
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

  Class['osnailyfacter::mysql_access'] -> Class['neutron::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
