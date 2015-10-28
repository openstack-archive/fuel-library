class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
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

class { 'Neutron::Db::Mysql':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  cluster_id    => 'localzone',
  collate       => 'utf8_general_ci',
  dbname        => 'neutron',
  host          => '127.0.0.1',
  name          => 'Neutron::Db::Mysql',
  password      => 'DVHUmPBa',
  user          => 'neutron',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Neutron::Db::Mysql]',
  db_host     => '10.122.12.2',
  db_password => 'sx2tGnw7',
  db_user     => 'root',
  name        => 'Osnailyfacter::Mysql_access',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

database { 'neutron':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'neutron',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'neutron@%/neutron':
  name       => 'neutron@%/neutron',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[neutron@%]',
}

database_grant { 'neutron@127.0.0.1/neutron':
  name       => 'neutron@127.0.0.1/neutron',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[neutron@127.0.0.1]',
}

database_grant { 'neutron@localhost/neutron':
  name       => 'neutron@localhost/neutron',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[neutron@localhost]',
}

database_grant { 'neutron@node-1/neutron':
  name       => 'neutron@node-1/neutron',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[neutron@node-1]',
}

database_user { 'neutron@%':
  name          => 'neutron@%',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@127.0.0.1':
  ensure        => 'present',
  name          => 'neutron@127.0.0.1',
  password_hash => '*AC1EFD51CB5142EA0A7535A70F5D6F0A3385C22E',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@localhost':
  name          => 'neutron@localhost',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@node-1':
  name          => 'neutron@node-1',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

file { '10.122.12.2-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = 'sx2tGnw7'
host     = '10.122.12.2'

[client]
user     = 'root'
password = 'sx2tGnw7'
host     = '10.122.12.2'

[mysqldump]
user     = 'root'
password = 'sx2tGnw7'
host     = '10.122.12.2'

[mysqladmin]
user     = 'root'
password = 'sx2tGnw7'
host     = '10.122.12.2'

[mysqlcheck]
user     = 'root'
password = 'sx2tGnw7'
host     = '10.122.12.2'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.10.122.12.2.cnf',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.10.122.12.2.cnf',
}

mysql::db { 'neutron':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'neutron',
  password    => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_%':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_%',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_127.0.0.1':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_127.0.0.1',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_localhost':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_localhost',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_node-1':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_node-1',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql { 'neutron':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'neutron',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'neutron',
  password_hash => '*D7CA334A3701D30ED5F6D7AE024243C6BABE80B5',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'neutron',
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

