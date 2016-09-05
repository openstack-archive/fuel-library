# == Class osnailyfacter::mysql_access
#
# Class that configures .my.cnf for services
#
# === Parameters:
#
# [*db_user*]
#  (optional) The mysql user to create
#  Defaults to 'root'
#
# [*db_password*]
#  Password to use for db_user
#
# [*ensure*]
#  (optional) Ensures to override .my.cnf
#  Defaults to 'present'
#
# [*db_host*]
#  (optional) The IP address of the mysql server
#  Defaults to '127.0.0.1'
class osnailyfacter::mysql_access (
  $ensure      = 'present',
  $db_user     = 'root',
  $db_password = '',
  $db_host     = 'localhost',
) {
  $default_file_path = "${::root_home}/.my.cnf"
  $host_file_path = "${::root_home}/.my.${db_host}.cnf"

  file { "${db_host}-mysql-access":
    ensure  => $ensure,
    path    => $host_file_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('osnailyfacter/mysql.access.cnf.erb')
  }

  if $ensure == 'present' {
    # .my.cnf is normally defined in mysql::server::root_password so
    # we need to override it with our version
    File <| title == $default_file_path |> {
      ensure  => 'symlink',
      content => undef,
      path    => $default_file_path,
      target  => $host_file_path,
    }

    File["${db_host}-mysql-access"] ->
    File <| path == $default_file_path |>

    # Ensure .my.cnf exists even if mysql on this node is disabled
    # TODO(dilyin): ensuring the default file is present is required for the external db configurations
    # TODO(dilyin): but it causes duplicate declaration errors on the controller. Some solution should be found.
    # TODO(dilyin): https://bugs.launchpad.net/fuel/+bug/1618607
    ensure_resource(file, $default_file_path)
  }
}
