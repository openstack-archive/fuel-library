$nova_hash      = hiera_hash('nova', {})
$mysql_hash     = hiera_hash('mysql', {})

$mysq_db_host        = fetch($mysql_hash, 'db_host')
$mysql_root_user     = fetch($mysql_hash, 'root_user', 'root')
$mysql_root_password = fetch($mysql_hash, 'root_password')
$mysql_db_create     = fetch($mysql_hash, 'db_create', true)

$db_user     = fetch($nova_hash, 'db_user', 'nova')
$db_name     = fetch($nova_hash, 'db_name', 'nova')
$db_password = fetch($nova_hash, 'db_password')

$db_host       = fetch($nova_hash, 'db_host', $mysq_db_host)
$db_create     = fetch($nova_hash, 'db_create', $mysql_db_create)
$root_user     = fetch($nova_hash, 'root_user', $mysql_root_user)
$root_password = fetch($nova_hash, 'root_password', $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $db_create {

  # Create the Keystone db
  class { 'nova::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  if $db_host and $root_user and $root_password {

    # Work with remote database host
    osnailyfacter::mysql_access { 'nova' :
      user     => $root_user,
      password => $root_password,
      host     => $db_host,
    }

    Osnailyfacter::Mysql_access['nova'] -> Class['nova::db::mysql']

  }
}
