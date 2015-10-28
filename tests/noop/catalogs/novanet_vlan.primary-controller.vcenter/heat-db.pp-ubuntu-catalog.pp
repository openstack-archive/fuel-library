class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Heat::Db::Mysql':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  name          => 'Heat::Db::Mysql',
  password      => 'vvKwC5nk',
  user          => 'heat',
}

class { 'Mysql::Config':
  name => 'Mysql::Config',
}

class { 'Mysql::Params':
  name => 'Mysql::Params',
}

class { 'Mysql::Python':
  name           => 'Mysql::Python',
  package_ensure => 'present',
  package_name   => 'python-mysqldb',
}

class { 'Mysql::Server':
  name => 'Mysql::Server',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Heat::Db::Mysql]',
  db_host     => '172.16.1.2',
  db_password => '4t67JmJk',
  db_user     => 'root',
  name        => 'Osnailyfacter::Mysql_access',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

database { 'heat':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'heat',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'heat@%/heat':
  name       => 'heat@%/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@%]',
}

database_grant { 'heat@127.0.0.1/heat':
  name       => 'heat@127.0.0.1/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@127.0.0.1]',
}

database_grant { 'heat@localhost/heat':
  name       => 'heat@localhost/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@localhost]',
}

database_grant { 'heat@node-3/heat':
  name       => 'heat@node-3/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@node-3]',
}

database_user { 'heat@%':
  name          => 'heat@%',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@127.0.0.1':
  ensure        => 'present',
  name          => 'heat@127.0.0.1',
  password_hash => '*8CFEDB43880C95A1F877E0A6650ACB2A7E9857F4',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@localhost':
  name          => 'heat@localhost',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@node-3':
  name          => 'heat@node-3',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

file { '172.16.1.2-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = '4t67JmJk'
host     = '172.16.1.2'

[client]
user     = 'root'
password = '4t67JmJk'
host     = '172.16.1.2'

[mysqldump]
user     = 'root'
password = '4t67JmJk'
host     = '172.16.1.2'

[mysqladmin]
user     = 'root'
password = '4t67JmJk'
host     = '172.16.1.2'

[mysqlcheck]
user     = 'root'
password = '4t67JmJk'
host     = '172.16.1.2'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.172.16.1.2.cnf',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.172.16.1.2.cnf',
}

mysql::db { 'heat':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'heat',
  password    => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_%':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_%',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_127.0.0.1':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_127.0.0.1',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_localhost':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_localhost',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_node-3':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_node-3',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql { 'heat':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'heat',
  password_hash => '*C8D6793D81CEF5DC2EA464B0E43131549133C5BD',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'heat',
}

package { 'mysql-client':
  name => 'mysql-client-5.6',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

stage { 'main':
  name => 'main',
}

