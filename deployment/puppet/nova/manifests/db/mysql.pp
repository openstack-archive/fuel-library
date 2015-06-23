# == Class: nova::db::mysql
#
# Class that configures mysql for nova
#
# === Parameters:
#
# [*password*]
#   Password to use for the nova user
#
# [*dbname*]
#   (optional) The name of the database
#   Defaults to 'nova'
#
# [*user*]
#   (optional) The mysql user to create
#   Defaults to 'nova'
#
# [*host*]
#   (optional) The IP address of the mysql server
#   Defaults to '127.0.0.1'
#
# [*charset*]
#   (optional) The charset to use for the nova database
#   Defaults to 'utf8'
#
# [*collate*]
#   (optional) The collate to use for the nova database
#   Defaults to 'utf8_general_ci'
#
# [*allowed_hosts*]
#   (optional) Additional hosts that are allowed to access this DB
#   Defaults to undef
#
# [*cluster_id*]
#   (optional) Deprecated. Does nothing
#   Defaults to 'localzone'
#
# [*mysql_module*]
#   (optional) Deprecated. Does nothing.
#
class nova::db::mysql(
  $password,
  $dbname        = 'nova',
  $user          = 'nova',
  $host          = '127.0.0.1',
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
  $allowed_hosts = undef,
  $mysql_module  = undef,
) {

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  if ($mysql_module >= 2.2) {
    ::openstacklib::db::mysql { 'nova':
      user          => $user,
      password_hash => mysql_password($password),
      dbname        => $dbname,
      host          => $host,
      charset       => $charset,
      collate       => $collate,
      allowed_hosts => $allowed_hosts,
    }

    ::Openstacklib::Db::Mysql['nova'] ~> Exec<| title == 'nova-db-sync' |>
  } else {
    # TODO (iberezovskiy): This woraround should be removed
    # after mysql module upgrade
    require 'mysql::python'

    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::config'],
    }

    # Create the db instance before openstack-nova if its installed
    Mysql::Db[$dbname] -> Anchor<| title == 'nova-start' |>
    Mysql::Db[$dbname] ~> Exec<| title == 'nova-db-sync' |>

    # Check allowed_hosts to avoid duplicate resource declarations
    if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
      $real_allowed_hosts = delete($allowed_hosts,$host)
    } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
      $real_allowed_hosts = $allowed_hosts
    }

    if $real_allowed_hosts {
      nova::db::mysql::host_access { $real_allowed_hosts:
        user          => $user,
        password      => $password,
        database      => $dbname,
        mysql_module  => $mysql_module,
      }
    }
  }
}
