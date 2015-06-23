$cinder_hash    = hiera_hash('cinder', {})
$mysql_hash     = hiera_hash('mysql', {})

$mysq_db_host        = fetch($mysql_hash, 'db_host')
$mysql_root_user     = fetch($mysql_hash, 'root_user', 'root')
$mysql_root_password = fetch($mysql_hash, 'root_password')
$mysql_db_create     = fetch($mysql_hash, 'db_create', true)

$db_user     = fetch($cinder_hash, 'db_user', 'cinder')
$db_name     = fetch($cinder_hash, 'db_name', 'cinder')
$db_password = fetch($cinder_hash, 'db_password')

$db_host       = fetch($cinder_hash, 'db_host', $mysq_db_host)
$db_create     = fetch($cinder_hash, 'db_create', $mysql_db_create)
$root_user     = fetch($cinder_hash, 'root_user', $mysql_root_user)
$root_password = fetch($cinder_hash, 'root_password', $mysql_root_password)

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
    osnailyfacter::mysql_access { 'cinder' :
      user     => $root_user,
      password => $root_password,
      host     => $db_host,
    }

    Osnailyfacter::Mysql_access['cinder'] -> Class['cinder::db::mysql']

  }
}
