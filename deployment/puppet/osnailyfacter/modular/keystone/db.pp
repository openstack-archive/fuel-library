notice('MODULAR: keystone/db.pp')

$node_name = hiera('node_name')
$network_metadata = hiera_hash('network_metadata', {})

$keystone_hash  = hiera_hash('keystone', {})
$mysql_hash     = hiera_hash('mysql', {})
$database_vip   = hiera('database_vip', undef)

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($keystone_hash['db_user'], 'keystone')
$db_name     = pick($keystone_hash['db_name'], 'keystone')
$db_password = pick($keystone_hash['db_password'], $mysql_root_password)

$db_host          = pick($keystone_hash['db_host'], $database_vip, 'localhost')
$db_create        = pick($keystone_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($keystone_hash['root_user'], $mysql_root_user)
$db_root_password = pick($keystone_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ $node_name, 'localhost', '127.0.0.1', '%' ]

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

  # TODO: stubs magic, should be fixed when galera/percona stuff is sorted out
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
  # TODO: it should be fixed as well.
  include ::galera::params
  class { 'mysql':
    package_name => $::galera::params::mysql_client_name,
  }

  class { 'keystone::db::mysql':
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
      Class['keystone::db::mysql']


}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
