# == Class osnailyfacter::mysql_user_access
#
# Class that creates a user and gives root access
#
# === Parameters:
#
# [*title*]
#  (required) The IP address of the networks to allow access from
#
# [*ensure*]
#  (optional) Ensures to override .my.cnf
#  Defaults to 'present'
#
# [*db_user*]
#  (optional) The mysql user to create
#  Defaults to 'root'
#
# [*db_password_hash*]
#  (optional) The mysql passowrd hash for the user
#  Defaults to ''
#
# [*access_networks*]
#  (optional) Array of networks to allow access from
#  Defaults to ['localhost']
#
class osnailyfacter::mysql_user_access (
  $ensure           = 'present',
  $db_user          = 'root',
  $db_password_hash = '',
  $access_networks  = ['localhost']
) {
  validate_array($access_networks)
  osnailyfacter::mysql_grant { $access_networks:
    user          => $db_user,
    password_hash => $db_password_hash
  }
}
