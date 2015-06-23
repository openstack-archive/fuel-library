$neutron_config = hiera_hash('neutron_config', {})
$mysql_hash     = hiera_hash('mysql', {})
$use_neutron    = hiera('use_neutron', false)
$database_vip   = hiera('database_vip', undef)

$mysql_db_host       = pick($mysql_hash, 'db_host', $database_vip)
$mysql_root_user     = pick($mysql_hash, 'root_user', 'root')
$mysql_root_password = pick($mysql_hash, 'root_password')
$mysql_db_create     = pick($mysql_hash, 'db_create', true)

$neutron_database_config = pick($neutron_config, 'database', {})

$db_user     = pick($neutron_database_config, 'db_user', 'neutron')
$db_name     = pick($neutron_database_config, 'db_name', 'neutron')
$db_password = pick($neutron_database_config, 'passwd')

$db_host       = pick($neutron_database_config, 'db_host', $mysql_db_host)
$db_create     = pick($neutron_database_config, 'db_create', $mysql_db_create)
$root_user     = pick($neutron_database_config, 'root_user', $mysql_root_user)
$root_password = pick($neutron_database_config, 'root_password', $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $use_neutron and $db_create {

  # Create the Keystone db
  class { 'neutron::db::mysql':
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

    Class['osnailyfacter::mysql_access'] -> Class['neutron::db::mysql']

  }
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
