# == Class osnailyfacter::mysql_root
#
# Class for root grant permissions
#
# [*password*]
#  Password to use with root user
#
class osnailyfacter::mysql_root (
  $password = '',
) {

  Exec {
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => '/root/.my.cnf',
  }

  exec { 'mysql_drop_test' :
    command => "mysql -NBe \"drop database if exists test\"",
  } ->

  exec { 'mysql_root_%' :
    command => "mysql -NBe \"grant all on *.* to 'root'@'%' with grant option\"",
  } ->

  exec { 'mysql_root_localhost' :
    command => "mysql -NBe \"grant all on *.* to 'root'@'localhost' with grant option\"",
  } ->

  exec { 'mysql_root_127.0.0.1' :
    command => "mysql -NBe \"grant all on *.* to 'root'@'127.0.0.1' with grant option\"",
  } ->

  exec { 'mysql_root_password' :
    command => "mysql -NBe \"update mysql.user set password = password('${password}') where user = 'root'\"",
  } ->

  exec { 'mysql_flush_privileges' :
    command => "mysql -NBe \"flush privileges\"",
  }

}
