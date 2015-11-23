class nailgun::postgresql(
  $postgres_default_version = $::nailgun::params::postgres_default_version,

  $nailgun_db_name = $::nailgun::params::nailgun_db_name,
  $nailgun_db_user = $::nailgun::params::nailgun_db_user,
  $nailgun_db_password = $::nailgun::params::nailgun_db_password,

  $keystone_db_name   = $::nailgun::params::keystone_db_name,
  $keystone_db_user   = $::nailgun::params::keystone_db_user,
  $keystone_db_password = $::nailgun::params::keystone_db_password,

  $ostf_db_name = $::nailgun::params::ostf_db_name,
  $ostf_db_user = $::nailgun::params::ostf_db_user,
  $ostf_db_password = $::nailgun::params::ostf_db_password,
) inherits nailgun::params {
  # install and configure postgresql server
  class { 'postgresql::globals':
    version             => $postgres_default_version,
    bindir              => "/usr/pgsql-${postgres_default_version}/bin",
    server_package_name => "postgresql-server",
    client_package_name => "postgresql",
    encoding            => 'UTF8',
  }
  class { 'postgresql::server':
    listen_addresses        => '0.0.0.0',
    ip_mask_allow_all_users => '0.0.0.0/0',
  }

  class { "nailgun::database":
    user      => $nailgun_db_user,
    password  => $nailgun_db_password,
    dbname    => $nailgun_db_name,
  }

  postgresql::server::db { $keystone_db_name:
    user     => $keystone_db_user,
    password => $keystone_db_password,
    grant    => 'all',
    require => Class['::postgresql::server'],
  }

  postgresql::server::db { $ostf_db_name:
    user     => $ostf_db_user,
    password => $ostf_db_password,
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
}
