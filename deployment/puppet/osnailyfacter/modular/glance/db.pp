notice('MODULAR: glance/db.pp')

$glance_hash    = hiera_hash('glance', {})
$mysql_hash     = hiera_hash('mysql', {})
$management_vip = hiera('management_vip')
$database_vip   = hiera('database_vip')

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($glance_hash['db_user'], 'glance')
$db_name     = pick($glance_hash['db_name'], 'glance')
$db_password = pick($glance_hash['db_password'], $mysql_root_password)

$db_host          = pick($glance_hash['db_host'], $database_vip, 'localhost')
$db_create        = pick($glance_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($glance_hash['root_user'], $mysql_root_user)
$db_root_password = pick($glance_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ hiera('node_name'), 'localhost', '127.0.0.1', '%' ]

validate_string($mysql_root_user)
validate_string($database_vip)

# TODO: clean the mess with custom_setup_class, galera::params and percona hardcodes
# in galera::params. Meanwhile we have to do some crazy stubs and calculations here.
$custom_setup_class = hiera('mysql_custom_setup_class', 'galera')

class galera (
  $use_percona          = false,
  $use_percona_packages = false,
){
  # do nothing here, it's a stub
}

if $db_create {

  if ($custom_setup_class == 'percona') {
    class { 'galera':
      use_percona          => true,
    }
  } elsif ($custom_setup_class == 'percona_packages') {
    class { 'galera':
      use_percona          => true,
      use_percona_packages => true
    }
  }

  # Now that we have correct 'galera' class stub with needed variables in its scope,
  # we can include galera::params and get proper $::galera::params::mysql_client_name
  include ::galera::params
  class { 'mysql':
    package_name => $::galera::params::mysql_client_name,
  }

  class { 'glance::db::mysql':
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

  Class['mysql'] ->
    Class['osnailyfacter::mysql_access'] ->
      Class['glance::db::mysql']
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
