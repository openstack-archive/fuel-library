# Allow a user to access the database for the service
#
# == Namevar
#  String with the form dbname_host. The host part of the string is the host
#  to allow
#
# == Parameters
#  [*user*]
#    username to allow
#
#  [*password_hash*]
#    user password hash
#
#  [*database*]
#    the database name
#
#  [*privileges*]
#    the privileges to grant to this user
#
#  [*mysql_module*]
#    Temp mysql_module vars that needed until mysql module is synced
#    do hardcode mysql_module=3.4 to avoid adding it to all modules
#
define openstacklib::db::mysql::host_access (
# Temp mysql_module variable untill mysql is up to date
  $user,
  $password_hash,
  $database,
  $privileges,
) {
  validate_re($title, '_', 'Title must be $dbname_$host')

  $host = inline_template('<%= @title.split("_").last %>')

  if !defined(Database_user["${user}@${host}"]) {
    database_user { "${user}@${host}":
      password_hash => $password_hash,
      provider      => 'mysql',
      require       => Database[$database],
    }
  }

  if !defined(Database_grant["${user}@${host}/${database}.*"]) {
    database_grant { "${user}@${host}/${database}.*":
      privileges => $privileges,
      table      => "${database}.*",
      user       => "${user}@${host}",
      require    => Database_user["${user}@${host}"]
    }
  }

}
