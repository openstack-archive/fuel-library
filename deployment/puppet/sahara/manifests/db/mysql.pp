# == Class: sahara::db::mysql
#
# The sahara::db::mysql class creates a MySQL database for sahara.
# It must be used on the MySQL server.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'sahara'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'sahara'.
#
# [*host*]
#   (Optional) The default source host user is allowed to connect from.
#   Defaults to '127.0.0.1'
#
# [*allowed_hosts*]
#   (Optional) Other hosts the user is allowed to connect from.
#   Defaults to 'undef'.
#
# [*charset*]
#   (Optional) The database charset.
#   Defaults to 'utf8'.
#
# [*collate*]
#   (Optional) Charset collate of sahara database.
#    Defaults to 'utf8_general_ci'.
#
class sahara::db::mysql(
  $password,
  $dbname        = 'sahara',
  $user          = 'sahara',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
) {

  validate_string($password)

  ::openstacklib::db::mysql{ 'sahara':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }

  ::Openstacklib::Db::Mysql['sahara'] ~> Exec<| title == 'sahara-dbmanage' |>
}
