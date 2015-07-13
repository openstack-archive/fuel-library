# == Class definition osnailyfacter::mysql_user
#
# Class for mysql user creation
#
# [*user*]
# Mysql username
#
# [*password*]
#  Password to use with user
#
# [*access_networks*]
#  Array of specific IPs or Networks or Hostnames
#  to access the database with user
#
define osnailyfacter::mysql_user (
  $user            = $name,
  $password        = '',
  $access_networks = '',
) {

  Exec {
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => '/root/.my.cnf',
  }

  osnailyfacter::mysql_access { $access_networks:
    user     => $user,
    password => $password,
    before   => Exec['mysql_root_password'],
    require  => Exec['mysql_drop_test'],
  }

  exec { 'mysql_drop_test' :
    command => "mysql -NBe \"drop database if exists test\"",
  }

  exec { 'mysql_root_password' :
    command => "mysql -NBe \"update mysql.user set password = password('${password}') where user = \'${user}\'\"",
  } ->

  exec { 'mysql_flush_privileges' :
    command => "mysql -NBe \"flush privileges\"",
  }
}
