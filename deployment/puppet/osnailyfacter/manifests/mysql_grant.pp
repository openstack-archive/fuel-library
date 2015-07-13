# == Class definition osnailyfacter::mysql_grant
#
# Class for mysql grant permissions
#
# [*user*]
# Mysql username
#
# [*network*]
#  Array of specific IPs or Networks or Hostnames
#  to access the database with user
#
define osnailyfacter::mysql_grant ( $user    = '',
                                    $network = $name ) {
  exec { "mysql_${user}_${network}":
    command => "mysql -NBe \"grant all on *.* to \'${user}\'@\'${network}\' with grant option\"",
  }
}
