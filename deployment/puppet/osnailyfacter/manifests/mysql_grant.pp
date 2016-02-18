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
  $user_title = "${user}@${network}"

  mysql_grant { "${user_title}/*.*":
    user       => $user_title,
    options    => ['GRANT'],
    privileges => ['ALL']
  }
}
