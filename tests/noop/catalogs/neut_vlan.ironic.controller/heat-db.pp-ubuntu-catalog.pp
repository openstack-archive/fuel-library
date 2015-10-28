class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Heat::Db::Mysql':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  name          => 'Heat::Db::Mysql',
  password      => 'qugZa4RJl8iT0K7060f1buWM',
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
  db_host     => '192.168.0.2',
  db_password => 'POvhJ6iQOcf9d4TCsul2ZRQI',
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

database_grant { 'heat@node-1/heat':
  name       => 'heat@node-1/heat',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[heat@node-1]',
}

database_user { 'heat@%':
  name          => 'heat@%',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@127.0.0.1':
  ensure        => 'present',
  name          => 'heat@127.0.0.1',
  password_hash => '*1AED012C058D6F8C898FC3D9F1442AC32E1AC0D3',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@localhost':
  name          => 'heat@localhost',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

database_user { 'heat@node-1':
  name          => 'heat@node-1',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  provider      => 'mysql',
  require       => 'Database[heat]',
}

file { '192.168.0.2-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = 'POvhJ6iQOcf9d4TCsul2ZRQI'
host     = '192.168.0.2'

[client]
user     = 'root'
password = 'POvhJ6iQOcf9d4TCsul2ZRQI'
host     = '192.168.0.2'

[mysqldump]
user     = 'root'
password = 'POvhJ6iQOcf9d4TCsul2ZRQI'
host     = '192.168.0.2'

[mysqladmin]
user     = 'root'
password = 'POvhJ6iQOcf9d4TCsul2ZRQI'
host     = '192.168.0.2'

[mysqlcheck]
user     = 'root'
password = 'POvhJ6iQOcf9d4TCsul2ZRQI'
host     = '192.168.0.2'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.192.168.0.2.cnf',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.192.168.0.2.cnf',
}

mysql::db { 'heat':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'heat',
  password    => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_%':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_%',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_127.0.0.1':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_127.0.0.1',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_localhost':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_localhost',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql::host_access { 'heat_node-1':
  database      => 'heat',
  mysql_module  => '0.3',
  name          => 'heat_node-1',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
  privileges    => 'ALL',
  user          => 'heat',
}

openstacklib::db::mysql { 'heat':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'heat',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'heat',
  password_hash => '*B0FE5EE578FA0FAF5F6B97FB7992D3E5A2C6E30E',
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

