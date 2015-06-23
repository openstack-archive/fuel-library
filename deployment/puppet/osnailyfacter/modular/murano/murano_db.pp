$murano_hash      = hiera_hash('murano', {})
$mysql_hash     = hiera_hash('mysql', {})

$mysq_db_host        = fetch($mysql_hash, 'db_host')
$mysql_root_user     = fetch($mysql_hash, 'root_user', 'root')
$mysql_root_password = fetch($mysql_hash, 'root_password')
$mysql_db_create     = fetch($mysql_hash, 'db_create', true)

$db_user     = fetch($murano_hash, 'db_user', 'murano')
$db_name     = fetch($murano_hash, 'db_name', 'murano')
$db_password = fetch($murano_hash, 'db_password')

$db_host       = fetch($murano_hash, 'db_host', $mysq_db_host)
$db_create     = fetch($murano_hash, 'db_create', $mysql_db_create)
$root_user     = fetch($murano_hash, 'root_user', $mysql_root_user)
$root_password = fetch($murano_hash, 'root_password', $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

if $db_create {

  # Create the Keystone db
  class { 'murano::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  if $db_host and $root_user and $root_password {

    # Work with remote database host
    osnailyfacter::mysql_access { 'murano' :
      user     => $root_user,
      password => $root_password,
      host     => $db_host,
    }

    Osnailyfacter::Mysql_access['murano'] -> Class['murano::db::mysql']

  }
}
