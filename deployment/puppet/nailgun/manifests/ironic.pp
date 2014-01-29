class nailgun::ironic(
  $db_host = $::ironic::params::db_host,
  $db_port = $::ironic::params::db_port,
  $db_protocol = $::ironic::params::db_protocol,
  $db_user = $::ironic::params::db_user,
  $db_password = $::ironic::params::db_password,
  $db_name = $::ironic::params::db_name,
  $venv = $::ironic::params::venv,
  ) inherits ironic::params {

  anchor { "ironic-begin": }
  anchor { "ironic-end": }

  Anchor<| title == "ironic-begin" |> ->
  class {'ironic::packages': } ->
  class {'ironic::rabbit': } ->
  class {'ironic::database': } ->
  class {'ironic::source': } ->
  class {'ironic::keystone::auth': } ->
  class {'ironic::conductor': } ->
  class {'ironic::api': } ->
  Anchor<| title == "ironic-end" |>

  Class["ironic::source"] ->

  ironic_config {
    'DEFAULT/sql_connection': value => "${db_protocol}://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}";
  } ->

  exec {"ironic_dbsync":
    command => "${venv}/bin/ironic-dbsync",
    require => Class["ironic::database"],
  } ->

  service {"ironic-api":
    ensure => "running",
    enable => true,
  } ->

  service {"ironic-conductor":
    ensure => "running",
    enable => true,
  }

}
