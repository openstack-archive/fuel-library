# == Type: osnailyfacter::mysql_grant
#
# Resource that can be used to apply a grant for a specific user.
#
# === Parameters
#
# [*network*]
#  Network name to provide access to from the user
#  Defaults to the title of the resource.
#
# [*user*]
#  (optional) Username to apply grant to
#  Defaults to 'root'
#
# [*password_hash*]
#  (optional) Password hash for the user
#  Defaults to ''
#
# [*database*]
#  (optional) Database name to provide access to
#  Defaults to '*'
#
# [*table*]
#  (optional) Database table to provide access to
#  Defaults to '*'
#
# [*options*]
#  (optional) The options to pass in to the grant
#  Defaults to ['GRANT']
#
# [*privileges*]
#  (optional) The privileges to apply for the grant
#  Defaults to ['ALL']
#
# === Example
#
#  # add root at multiple hosts
#  $networks = ['1.1.1.1', '2.2.2.2']
#  osnailyfacter::mysql_grant { $networks:
#    password_hash => mysql_password('apassword')
#  }
#
define osnailyfacter::mysql_grant (
  $network       = $title,
  $user          = 'root',
  $password_hash = '',
  $database      = '*',
  $table         = '*',
  $options       = ['GRANT'],
  $privileges    = ['ALL']
) {
  $user_title = "${user}@${network}"
  $database_table = "${database}.${table}"

  mysql_user { $user_title:
    password_hash => $password_hash
  } ->
  mysql_grant { "${user_title}/${database_table}":
    user       => $user_title,
    table      => $database_table,
    options    => $options,
    privileges => $privileges,
  }
}
