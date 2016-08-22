class fuel::postgresql(
  $nailgun_db_name          = $::fuel::params::nailgun_db_name,
  $nailgun_db_user          = $::fuel::params::nailgun_db_user,
  $nailgun_db_password      = $::fuel::params::nailgun_db_password,

  $keystone_db_name         = $::fuel::params::keystone_db_name,
  $keystone_db_user         = $::fuel::params::keystone_db_user,
  $keystone_db_password     = $::fuel::params::keystone_db_password,

  $ostf_db_name             = $::fuel::params::ostf_db_name,
  $ostf_db_user             = $::fuel::params::ostf_db_user,
  $ostf_db_password         = $::fuel::params::ostf_db_password,
) inherits fuel::params {

  # install and configure postgresql server
  class { 'postgresql::globals':
    server_package_name => "postgresql-server",
    client_package_name => "postgresql",
    encoding            => 'UTF8',
  }

  class { 'postgresql::server':
    listen_addresses        => '0.0.0.0',
    ip_mask_allow_all_users => '0.0.0.0/0',
  }

  postgresql::server::db { $nailgun_db_name :
    user     => $nailgun_db_user,
    password => $nailgun_db_password,
    grant    => 'all',
    require  => Class['::postgresql::server'],
  }

  postgresql::server::db { $keystone_db_name:
    user     => $keystone_db_user,
    password => $keystone_db_password,
    grant    => 'all',
    require  => Class['::postgresql::server'],
  }

  postgresql::server::db { $ostf_db_name:
    user     => $ostf_db_user,
    password => $ostf_db_password,
    grant    => 'all',
    require  => Class['::postgresql::server'],
  }

  ensure_packages(['python-psycopg2', 'postgresql-libs'])
}
