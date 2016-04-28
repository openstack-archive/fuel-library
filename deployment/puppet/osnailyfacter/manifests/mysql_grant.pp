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
define osnailyfacter::mysql_grant (
  $user    = '',
  $network = $name
) {

  $user_identity = "${user}@${network}"

  database_grant { "${user_identity}/*.*":
    user       => $user_identity,
    table      => '*.*',
    options    => ['GRANT'],
    privileges => ['ALL']
  }

}
