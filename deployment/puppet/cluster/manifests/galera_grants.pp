# == Class: cluster::galera_grants
#
# Configures a user that will check the status
# of galera cluster, assumes mysql module is in catalog
#
# === Parameters:
#
# [*status_user*]
# (optiona) The name of user to use for status checks
# Defaults to false
#
# [*status_password*]
# (optional) The password of the status check user
# Defaults to false
#
# [*status_allow*]
# (optional) The subnet to allow status checks from
# Defaults to '%'
#

class cluster::galera_grants (
  $status_user     = false,
  $status_password = false,
  $status_allow    = '%',
) {

  validate_string($status_user, $status_password)

  mysql_user { "${status_user}@${status_allow}":
    ensure        => 'present',
    password_hash => mysql_password($status_password),
    require       => Anchor['mysql::server::end'],
  } ->
  mysql_grant { "${status_user}@${status_allow}/*.*":
    ensure     => 'present',
    options    => [ 'GRANT' ],
    privileges => [ 'USAGE' ],
    table      => '*.*',
    user       => "${status_user}@${status_allow}",
  }
}
