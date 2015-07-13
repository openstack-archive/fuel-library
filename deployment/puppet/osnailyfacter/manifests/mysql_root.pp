# == Class osnailyfacter::mysql_root
#
# Class for root grant permissions
#
# [*password*]
#  Password to use with root user
#
# [*other_networks*]
#  List of specific IPs or Networks to access
#  the database
#
class osnailyfacter::mysql_root (
  $password = '',
  $other_networks = '240.0.0.2 240.0.0.6',
) {

  $network_array = split($other_networks, ' ')

  Exec {
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => '/root/.my.cnf',
  }

  define mysql_for_other_networks () {
    exec { "mysql_root_${name}":
      command => "mysql -NBe \"grant all on *.* to 'root'@\'${name}\' with grant option\"",
      before  => Exec['mysql_flush_privileges'],
    }
  }

  exec { 'mysql_drop_test' :
    command => "mysql -NBe \"drop database if exists test\"",
  } ->

  mysql_for_other_networks { $network_array: }

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
