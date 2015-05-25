$fuel_settings = parseyaml($astute_settings_yaml)

$postgres_default_version = '9.3'

# install and configure postgresql server
class { 'postgresql::globals':
  version             => $postgres_default_version,
  bindir              => "/usr/pgsql-${postgres_default_version}/bin",
  server_package_name => "postgresql-server",
  client_package_name => "postgresql",
}
class { 'postgresql::server':
  listen_addresses        => '0.0.0.0',
  ip_mask_allow_all_users => '0.0.0.0/0',
}

# nailgun db and grants
$database_name = $::fuel_settings['postgres']['nailgun_dbname']
$database_engine = "postgresql"
$database_port = "5432"
$database_user = $::fuel_settings['postgres']['nailgun_user']
$database_passwd = $::fuel_settings['postgres']['nailgun_password']

class {'docker::container': }

class { "nailgun::database":
  user      => $database_user,
  password  => $database_passwd,
  dbname    => $database_name,
}

# keystone db and grants
$keystone_dbname   = $::fuel_settings['postgres']['keystone_dbname']
$keystone_dbuser   = $::fuel_settings['postgres']['keystone_user']
$keystone_dbpass   = $::fuel_settings['postgres']['keystone_password']

postgresql::server::db { $keystone_dbname:
  user     => $keystone_dbuser,
  password => $keystone_dbpass,
  grant    => 'all',
  require => Class['::postgresql::server'],
}

# ostf db and grants
$ostf_dbname   = $::fuel_settings['postgres']['ostf_dbname']
$ostf_dbuser   = $::fuel_settings['postgres']['ostf_user']
$ostf_dbpass   = $::fuel_settings['postgres']['ostf_password']

postgresql::server::db { $ostf_dbname:
  user     => $ostf_dbuser,
  password => $ostf_dbpass,
  grant    => 'all',
  require => Class['::postgresql::server'],
}

Class['postgresql::server'] -> Postgres_config<||>
Postgres_config { ensure => present }
postgres_config {
  log_directory     : value => "'/var/log/'";
  log_filename      : value => "'pgsql'";
  log_rotation_age  : value => "7d";
}

