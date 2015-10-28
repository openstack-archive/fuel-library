class { 'Cinder::Db::Mysql':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  cluster_id    => 'localzone',
  collate       => 'utf8_general_ci',
  dbname        => 'cinder',
  host          => '127.0.0.1',
  name          => 'Cinder::Db::Mysql',
  password      => 'Q4I97R7I',
  user          => 'cinder',
}

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

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Cinder::Db::Mysql]',
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

database { 'cinder':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'cinder',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'cinder@%/cinder':
  name       => 'cinder@%/cinder',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[cinder@%]',
}

database_grant { 'cinder@127.0.0.1/cinder':
  name       => 'cinder@127.0.0.1/cinder',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[cinder@127.0.0.1]',
}

database_grant { 'cinder@localhost/cinder':
  name       => 'cinder@localhost/cinder',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[cinder@localhost]',
}

database_grant { 'cinder@node-3/cinder':
  name       => 'cinder@node-3/cinder',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[cinder@node-3]',
}

database_user { 'cinder@%':
  name          => 'cinder@%',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  provider      => 'mysql',
  require       => 'Database[cinder]',
}

database_user { 'cinder@127.0.0.1':
  ensure        => 'present',
  name          => 'cinder@127.0.0.1',
  password_hash => '*9BE06BFF66036A5EECBA3D252A8C0A9923616A6D',
  provider      => 'mysql',
  require       => 'Database[cinder]',
}

database_user { 'cinder@localhost':
  name          => 'cinder@localhost',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  provider      => 'mysql',
  require       => 'Database[cinder]',
}

database_user { 'cinder@node-3':
  name          => 'cinder@node-3',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  provider      => 'mysql',
  require       => 'Database[cinder]',
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

mysql::db { 'cinder':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'cinder',
  password    => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_%':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_%',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_127.0.0.1':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_127.0.0.1',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_localhost':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_localhost',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_node-3':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_node-3',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql { 'cinder':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'cinder',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'cinder',
  password_hash => '*B1439F4F294D2FAE921522BCA95FA7FBE1890A02',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'cinder',
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

