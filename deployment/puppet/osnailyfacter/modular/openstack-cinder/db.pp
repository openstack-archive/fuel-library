notice('MODULAR: cinder/db.pp')

$cinder_hash    = hiera_hash('cinder', {})
$mysql_hash     = hiera_hash('mysql_hash', {})
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($cinder_hash['db_user'], 'cinder')
$db_name     = pick($cinder_hash['db_name'], 'cinder')
$db_password = pick($cinder_hash['db_password'], $mysql_root_password)

$db_host          = pick($cinder_hash['db_host'], $database_vip, $management_vip, 'localhost')
$db_create        = pick($cinder_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($cinder_hash['root_user'], $mysql_root_user)
$db_root_password = pick($cinder_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ $::hostname, 'localhost', '127.0.0.1', '%' ]

validate_string($mysql_root_user)

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

  class { 'cinder::db::mysql':
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
      Class['cinder::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
