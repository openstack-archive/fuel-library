# == Class osnailyfacter::mysql_user_access
#
# Class that creates a user and gives *root* access for an array of hosts or
# networks.
#
# === Parameters:
#
# [*title*]
#  (required) The IP address of the networks to allow access from
#
# [*db_user*]
#  (optional) The mysql user to create
#  Defaults to 'root'
#
# [*db_password_hash*]
#  (optional) The mysql password hash for the user
#  Defaults to ''
#
# [*access_networks*]
#  (optional) Array of networks to allow access from
#  Defaults to ['localhost']
#
class osnailyfacter::mysql_user_access (
  $db_user          = 'root',
  $db_password_hash = '',
  $access_networks  = ['localhost']
) {
  validate_array($access_networks)
  ::osnailyfacter::mysql_grant { $access_networks:
    user          => $db_user,
    password_hash => $db_password_hash
  }
}
