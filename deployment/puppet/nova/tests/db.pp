class { 'nova': 
  sql_connection => 'mysql://root:<password>@127.0.0.1/nova',
}

class { 'nova::db::mysql':
  password => 'password',
  dbname   => 'nova',
  user     => 'nova',
  host     => 'localhost',
}
