# == Class osnailyfacter::mysql_user
#
# Class for mysql user creation and grant permissions
#
# [*user*]
#  (optional) Mysql user name. Default 'root'
#
# [*password*]
#  Password to use with mysql user
#
# [*access_networks*]
#  Array of specific IPs or Networks or Hostnames
#  to access the database with mysql user.
#  Default '127.0.0.1'
#
class osnailyfacter::mysql_user (
  $user            = 'root',
  $password        = '',
  $access_networks = '127.0.0.1',
) {

  Exec {
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => '/root/.my.cnf',
  }

  exec { 'mysql_drop_test' :
    command => "mysql -NBe \"drop database if exists test\"",
  } ->

  osnailyfacter::mysql_grant { $access_networks:
    user => $user,
  } ->

  exec { "mysql_${user}_password" :
    command => "mysql -NBe \"update mysql.user set password = password('${password}') where user = \'${user}\'\"",
  } ->

  exec { 'mysql_flush_privileges' :
    command => "mysql -NBe \"flush privileges\"",
  }
}

