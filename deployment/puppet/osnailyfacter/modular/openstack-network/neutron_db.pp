$network_config = hiera_hash('network_config', {})
$mysql_hash     = hiera_hash('mysql', {})
$use_neutron    = hiera('use_neutron', false)

$mysq_db_host        = fetch($mysql_hash, 'db_host')
$mysql_root_user     = fetch($mysql_hash, 'root_user', 'root')
$mysql_root_password = fetch($mysql_hash, 'root_password')
$mysql_db_create     = fetch($mysql_hash, 'db_create', true)

$db_user     = fetch($network_config, 'database/db_user', 'neutron')
$db_name     = fetch($network_config, 'database/db_name', 'neutron')
$db_password = fetch($network_config, 'database/passwd')

$db_host       = fetch($network_config, 'database/db_host', $mysq_db_host)
$db_create     = fetch($network_config, 'database/db_create', $mysql_db_create)
$root_user     = fetch($network_config, 'database/root_user', $mysql_root_user)
$root_password = fetch($network_config, 'database/root_password', $mysql_root_password)

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
    osnailyfacter::mysql_access { 'neutron' :
      user     => $root_user,
      password => $root_password,
      host     => $db_host,
    }

    Osnailyfacter::Mysql_access['neutron'] -> Class['neutron::db::mysql']

  }
}
