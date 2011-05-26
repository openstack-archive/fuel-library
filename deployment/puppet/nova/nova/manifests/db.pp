class nova::db(
  $db_pw,
  $db_user = 'nova'
  $db_name = 'nova',
  $db_host => 'localhost'
) {
  mysql::db { $db_name:
    db_user => $db_user, 
    db_pw => $db_pw,  
    db_hostname => $db_hostname,
    # I may want to inject some sql
    # sql='',
    require => Class['mysql::server']
  }
}
