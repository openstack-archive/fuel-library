class nova::db(
  $password,
  $name = 'nova',
  $user = 'nova',
  $host = 'localhost'
) {
  mysql::db { $name:
    user => $user, 
    password => $password,  
    host => $host,
    # I may want to inject some sql
    # sql='',
    require => Class['mysql::server'],
  }
}
