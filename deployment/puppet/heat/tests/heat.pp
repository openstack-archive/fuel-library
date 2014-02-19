class { 'heat' :
  pacemaker       => false,
  rabbit_host     => '127.0.0.1',
  rabbit_login    => 'heat',
  rabbit_password => 'secret',
  db_password     => 'secret',
}
