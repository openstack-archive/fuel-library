class { 'mysql::server':
  root_password => 'password' 
}
class { 'nova::db':
  password => 'password',
  name     => 'nova',
  user     => 'nova',
  host     => 'localhost',
}
