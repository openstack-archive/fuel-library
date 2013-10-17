class { 'heat' :
  pacemaker            => false,
  heat_rabbit_host     => '127.0.0.1',
  heat_rabbit_login    => 'heat',
  heat_rabbit_password => 'secret',
  heat_db_password     => 'secret',
}