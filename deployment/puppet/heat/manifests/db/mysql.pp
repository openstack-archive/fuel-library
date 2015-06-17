# == Class: heat::db::mysql
#
# The heat::db::mysql class creates a MySQL database for heat.
# It must be used on the MySQL server
#
# === Parameters
#
# [*password*]
#   (Mandatory) Password to connect to the database.
#   Defaults to 'false'.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'heat'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'heat'.
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
#   Defaults to 'utf8'
#
# [*collate*]
#   (Optional) The database collate.
#   Only used with mysql modules >= 2.2.
#   Defaults to 'utf8_general_ci'
#
# === Deprecated Parameters
#
# [*mysql_module*]
#   (Optional) Does nothing.
#
class heat::db::mysql(
  $password      = false,
  $dbname        = 'heat',
  $user          = 'heat',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
  $mysql_module  = undef
) {

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  validate_string($password)


  # This workaround should be removed after mysql module upgrade
  if ($mysql_module >= 2.2) {
    ::openstacklib::db::mysql { 'heat':
      user          => $user,
      password_hash => mysql_password($password),
      dbname        => $dbname,
      host          => $host,
      charset       => $charset,
      collate       => $collate,
      allowed_hosts => $allowed_hosts,
    }

    ::Openstacklib::Db::Mysql['heat'] ~> Exec<| title == 'heat-dbsync' |>
  } else {
    mysql::db { $dbname:
      user     => $user,
      password => $password,
      host     => $host,
      charset  => $charset,
      require  => Class['mysql::config'],
    }

    Mysql::Db["$dbname"] ~> Exec<| title == 'heat-dbsync' |>

    # Check allowed_hosts to avoid duplicate resource declarations
    if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
      $real_allowed_hosts = delete($allowed_hosts,$host)
    } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
      $real_allowed_hosts = $allowed_hosts
    }

    if $real_allowed_hosts {
      heat::db::mysql::host_access { $real_allowed_hosts:
        user          => $user,
        password      => $password,
        database      => $dbname,
        mysql_module  => $mysql_module,
      }
    }
  }
}
