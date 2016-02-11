notice('MODULAR: aodh/db.pp')

$aodh_hash    = hiera_hash('aodh', {'db' => { 'user_password' => 'aodh' }})
$database_vip = hiera('database_vip')

$db_type          = pick($aodh_hash['db']['type'], 'mysql')
$db_user          = pick($aodh_hash['db']['user_name'], 'aodh')
$db_name          = pick($aodh_hash['db']['database'], 'aodh')
$db_password      = $aodh_hash['db']['user_password']
$db_host          = pick($aodh_hash['db']['db_host'], $database_vip)
$db_collate       = pick($aodh_hash['db']['collate'], 'utf8_general_ci')
$db_charset       = pick($aodh_hash['db']['charset'], 'utf8')
$db_allowed_host  = pick($aodh_hash['db']['allowed_host'], '127.0.0.1')
$db_allowed_hosts = pick($aodh_hash['db']['allowed_hosts'], '%')

$mysql_hash          = hiera_hash('mysql_hash', {})
$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_root_password = $mysql_hash['root_password']
$db_root_user        = pick($aodh_hash['root_user'], $mysql_root_user)
$db_root_password    = pick($aodh_hash['root_password'], $mysql_root_password)

class { 'aodh::db::mysql':
  user          => $db_user,
  password      => $db_password,
  dbname        => $db_name,
  host          => $db_allowed_host,
  charset       => $db_charset,
  collate       => $db_collate,
  allowed_hosts => $db_allowed_hosts,
}

class { 'osnailyfacter::mysql_access':
  db_host     => $db_host,
  db_user     => $db_root_user,
  db_password => $db_root_password,
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
