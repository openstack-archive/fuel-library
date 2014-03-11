class sahara::db::mysql(
  $password      = 'sahara',
  $dbname        = 'sahara',
  $user          = 'sahara',
  $dbhost        = 'localhost',
  $charset       = 'utf8',
  $allowed_hosts = undef,
) {

  include 'sahara::params'

  mysql::db { $dbname :
    user     => $user,
    password => $password,
    host     => $dbhost,
    charset  => $charset,
    grant    => ['all'],
  }

  if $allowed_hosts {
    sahara::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

  Database[$dbname] -> Class['sahara::api']
  Database_user["${user}@${dbhost}"] -> Class['sahara::api']
  Database_grant["${user}@${dbhost}/${dbname}"] -> Class['sahara::api']

}
