# == Class sahara::db::mysql
#
# Class that configures mysql for sahara
#
# === Parameters:
#
# [*password*]
#   Password to use for the sahara user
#
# [*dbname*]
#   (optional) The name of the database
#   Defaults to 'sahara'
#
# [*user*]
#   (optional) The mysql user to create
#   Defaults to 'sahara'
#
# [*host*]
#   (optional) The IP address of the mysql server
#   Defaults to '127.0.0.1'
#
# [*charset*]
#   (optional) The charset to use for the sahara database
#   Defaults to 'utf8'
#
# [*collate*]
#   (optional) The collate to use for the sahara database
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
#   (optional) Mysql puppet module version to use. Tested versions
#   are 0.9 and 2.2.
#   Defaults to '0.9'
#
class sahara::db::mysql(
  $password,
  $dbname        = 'sahara',
  $user          = 'sahara',
  $dbhost        = '127.0.0.1',
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
  $allowed_hosts = undef,
  $mysql_module  = '0.9'
) {

  if ($mysql_module >= 2.2) {
    mysql::db { $dbname:
      user     => $user,
      password => $password,
      host     => $dbhost,
      charset  => $charset,
      collate  => $collate,
      require  => Class['mysql::server'],
    }
  } else {
    require 'mysql::python'

    mysql::db { $dbname:
      user     => $user,
      password => $password,
      host     => $dbhost,
      charset  => $charset,
      require  => Class['mysql::config'],
    }
  }

  # Check allowed_hosts to avoid duplicate resource declarations
  if is_array($allowed_hosts) and delete($allowed_hosts,$dbhost) != [] {
    $real_allowed_hosts = delete($allowed_hosts,$dbhost)
  } elsif is_string($allowed_hosts) and ($allowed_hosts != $dbhost) {
    $real_allowed_hosts = $allowed_hosts
  }

  if $real_allowed_hosts {
    sahara::db::mysql::host_access { $real_allowed_hosts:
      user         => $user,
      password     => $password,
      database     => $dbname,
      mysql_module => $mysql_module,
    }
  }

  Database[$dbname] -> Class['sahara::api']
  Database_user["${user}@${dbhost}"] -> Class['sahara::api']
  Database_grant["${user}@${dbhost}/${dbname}"] -> Class['sahara::api']

}
