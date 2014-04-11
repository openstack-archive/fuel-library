class murano::db::mysql(
  $password      = 'murano',
  $dbname        = 'murano',
  $user          = 'murano',
  $dbhost        = 'localhost',
  $charset       = 'utf8',
  $allowed_hosts = undef,
) {

  include 'murano::params'

  mysql::db { $dbname :
    user     => $user,
    password => $password,
    host     => $dbhost,
    charset  => $charset,
    grant    => ['all'],
  }
  
  if $allowed_hosts {
    murano::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }
  
  $services = [ 'murano::api' ]
  # TODO(dteselkin): Update the line above similar
  # to the line below when murano::engine is added.
  #$services = [ 'murano::conductor', 'murano::api' ]
  Database[$dbname] -> Class[$services]
  Database_user["${user}@${dbhost}"] -> Class[$services]
  Database_grant["${user}@${dbhost}/${dbname}"] -> Class[$services]

}
