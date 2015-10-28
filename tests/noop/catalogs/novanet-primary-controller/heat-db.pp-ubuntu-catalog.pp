class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Heat::Db::Mysql':
  allowed_hosts => ['node-137', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  name          => 'Heat::Db::Mysql',
  password      => 'SvgZ3tKP',
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
  db_host     => '192.168.0.5',
  db_password => 'M3VTf8U9',
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

database_grant { 'heat@node-137/heat':
  name       => 'heat@node-137/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@node-137]',
}

database_user { 'heat@%':
  name          => 'heat@%',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@127.0.0.1':
  ensure        => 'present',
  name          => 'heat@127.0.0.1',
  password_hash => '*C410EF08761816932F23DCA7B6C52636A6C93B84',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@localhost':
  name          => 'heat@localhost',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@node-137':
  name          => 'heat@node-137',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

file { '192.168.0.5-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = 'M3VTf8U9'
host     = '192.168.0.5'

[client]
user     = 'root'
password = 'M3VTf8U9'
host     = '192.168.0.5'

[mysqldump]
user     = 'root'
password = 'M3VTf8U9'
host     = '192.168.0.5'

[mysqladmin]
user     = 'root'
password = 'M3VTf8U9'
host     = '192.168.0.5'

[mysqlcheck]
user     = 'root'
password = 'M3VTf8U9'
host     = '192.168.0.5'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.192.168.0.5.cnf',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.192.168.0.5.cnf',
}

mysql::db { 'heat':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'heat',
  password    => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_%':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_%',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_127.0.0.1':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_127.0.0.1',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_localhost':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_localhost',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_node-137':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_node-137',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql { 'heat':
  allowed_hosts => ['node-137', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'heat',
  password_hash => '*B530119AC1549234F8E822B399AC9BBD3362088C',
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

