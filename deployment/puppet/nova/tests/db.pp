class { 'nova': 
  sql_connection => 'mysql://root:<password>@127.0.0.1/nova',
}
class { 'mysql::server':
  root_password => 'password' 
}
class { 'nova::db':
  password => 'password',
  dbname   => 'nova',
  user     => 'nova',
  host     => 'localhost',
}
