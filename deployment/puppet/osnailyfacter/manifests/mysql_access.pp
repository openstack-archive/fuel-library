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
# [*db_host*]
#  (optional) The IP address of the mysql server
#  Defaults to '127.0.0.1'
#
class osnailyfacter::mysql_access (
  $ensure      = 'present',
  $db_user     = 'root',
  $db_password = '',
  $db_host     = 'localhost',
) {
  $default_file_path = '/root/.my.cnf'
  $host_file_path = "/root/.my.${db_host}.cnf"

  file { "${db_host}-mysql-access":
    ensure  => $ensure,
    path    => $host_file_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('osnailyfacter/mysql.access.cnf.erb')
  }

  if $ensure == 'present' {
    file { 'default-mysql-access-link':
      ensure => 'symlink',
      path   => $default_file_path,
      target => $host_file_path,
    }
  }
}
