$fuel_settings = parseyaml($astute_settings_yaml)

$postgres_default_version = '8.4'

# install and configure postgresql server
class { 'postgresql::globals':
  version             => $postgres_default_version,
  bindir              => "/usr/bin",
  server_package_name => "postgresql-server",
  client_package_name => "postgresql",
}
class { 'postgresql::server':
  listen_addresses        => '0.0.0.0',
  ip_mask_allow_all_users => '0.0.0.0/0',
}

# nailgun db and grants
$database_name = "nailgun"
$database_engine = "postgresql"
$database_port = "5432"
$database_user = "nailgun"
$database_passwd = "nailgun"

class { "nailgun::database":
  user      => $database_user,
  password  => $database_passwd,
  dbname    => $database_name,
}

# ostf db and grants
$dbuser   = 'ostf'
$dbpass   = 'ostf'
$dbname   = 'ostf'

postgresql::server::db { $ostf_dbname:
  user     => $ostf_dbuser,
  password => $ostf_dbpass,
  grant    => 'all',
  require => Class['::postgresql::server'],
}
