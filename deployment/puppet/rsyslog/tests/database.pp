include rsyslog

class { 'rsyslog::database':
  backend  => 'mysql',
  server   => 'localhost',
  database => 'Syslog',
  username => 'rsyslog',
  password => 'secret',
}
