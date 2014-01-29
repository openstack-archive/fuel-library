class ironic::database(
  $db_host = $::ironic::params::db_host,
  $db_port = $::ironic::params::db_port,
  $db_protocol = $::ironic::params::db_protocol,
  $db_user = $::ironic::params::db_user,
  $db_password = $::ironic::params::db_password,
  $db_name = $::ironic::params::db_name,
  ) inherits ironic::params {

  postgresql::db{ $db_name:
    user     => $db_user,
    password => $db_password,
    grant    => 'all',
    require  => Class['::postgresql::server'],
  }

}
