# == Class definition osnailyfacter::mysql_access
#
# Class for mysql grant permissions
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
define osnailyfacter::mysql_access (
  $user           = $name,
  $password       = '',
  $other_networks = '',
) {

  Exec {
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    creates => '/root/.my.cnf',
  }

  define mysql_grant ( $user ) {
    exec { "mysql_root_${name}":
      command => "mysql -NBe \"grant all on *.* to \'${user}\'@\'${name}\' with grant option\"",
      before  => Exec['mysql_root_password'],
      require => Exec['mysql_drop_test'],
    }
  }

  mysql_grant { $network_array:
    user => $user,
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
