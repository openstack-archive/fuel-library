$neutron_config = hiera_hash('neutron_config', {})
$mysql_hash     = hiera_hash('mysql', {})
$use_neutron    = hiera('use_neutron', false)

$mysq_db_host        = fetch($mysql_hash, 'db_host')
$mysql_root_user     = fetch($mysql_hash, 'root_user', 'root')
$mysql_root_password = fetch($mysql_hash, 'root_password')
$mysql_db_create     = fetch($mysql_hash, 'db_create', true)

$db_user     = fetch($neutron_config, 'database/db_user', 'neutron')
$db_name     = fetch($neutron_config, 'database/db_name', 'neutron')
$db_password = fetch($neutron_config, 'database/passwd')

$db_host       = fetch($neutron_config, 'database/db_host', $mysq_db_host)
$db_create     = fetch($neutron_config, 'database/db_create', $mysql_db_create)
$root_user     = fetch($neutron_config, 'database/root_user', $mysql_root_user)
$root_password = fetch($neutron_config, 'database/root_password', $mysql_root_password)

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
      user     => $root_user,
      password => $root_password,
      host     => $db_host,
    }

    Class['osnailyfacter::mysql_access'] -> Class['neutron::db::mysql']

  }
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
