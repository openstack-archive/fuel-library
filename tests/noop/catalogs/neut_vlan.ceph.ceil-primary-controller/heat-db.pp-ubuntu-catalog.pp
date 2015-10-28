class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Heat::Db::Mysql':
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  name          => 'Heat::Db::Mysql',
  password      => 'NTeyraV2',
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
  db_host     => '192.168.0.7',
  db_password => '5eqwkxY3',
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

database_grant { 'heat@node-125/heat':
  name       => 'heat@node-125/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@node-125]',
}

database_user { 'heat@%':
  name          => 'heat@%',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@127.0.0.1':
  ensure        => 'present',
  name          => 'heat@127.0.0.1',
  password_hash => '*A8626D4A119364D53F47D4FAC3346B87A5E21035',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@localhost':
  name          => 'heat@localhost',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@node-125':
  name          => 'heat@node-125',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

file { '192.168.0.7-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = '5eqwkxY3'
host     = '192.168.0.7'

[client]
user     = 'root'
password = '5eqwkxY3'
host     = '192.168.0.7'

[mysqldump]
user     = 'root'
password = '5eqwkxY3'
host     = '192.168.0.7'

[mysqladmin]
user     = 'root'
password = '5eqwkxY3'
host     = '192.168.0.7'

[mysqlcheck]
user     = 'root'
password = '5eqwkxY3'
host     = '192.168.0.7'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.192.168.0.7.cnf',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.192.168.0.7.cnf',
}

mysql::db { 'heat':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'heat',
  password    => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_%':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_%',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_127.0.0.1':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_127.0.0.1',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_localhost':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_localhost',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_node-125':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_node-125',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql { 'heat':
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'heat',
  password_hash => '*85780DB945DD62D9B1CC5FF71294B51C8A2D2A15',
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

