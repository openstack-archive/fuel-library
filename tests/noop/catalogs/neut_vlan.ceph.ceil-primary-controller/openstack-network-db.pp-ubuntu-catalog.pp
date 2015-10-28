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
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  cluster_id    => 'localzone',
  collate       => 'utf8_general_ci',
  dbname        => 'neutron',
  host          => '127.0.0.1',
  name          => 'Neutron::Db::Mysql',
  password      => 'zOXpcc6c',
  user          => 'neutron',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Neutron::Db::Mysql]',
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

database_grant { 'neutron@node-125/neutron':
  name       => 'neutron@node-125/neutron',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[neutron@node-125]',
}

database_user { 'neutron@%':
  name          => 'neutron@%',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@127.0.0.1':
  ensure        => 'present',
  name          => 'neutron@127.0.0.1',
  password_hash => '*EF99A3569D1B97D8F52E9941F4036334927BADC9',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@localhost':
  name          => 'neutron@localhost',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@node-125':
  name          => 'neutron@node-125',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  provider      => 'mysql',
  require       => 'Database[neutron]',
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

mysql::db { 'neutron':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'neutron',
  password    => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_%':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_%',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_127.0.0.1':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_127.0.0.1',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_localhost':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_localhost',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_node-125':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_node-125',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql { 'neutron':
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'neutron',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'neutron',
  password_hash => '*ACF26E1169B3BDA82E7DBBC652B0B5D087FD25CA',
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

