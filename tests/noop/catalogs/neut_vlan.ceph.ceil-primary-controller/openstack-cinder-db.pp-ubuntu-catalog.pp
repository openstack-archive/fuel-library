class { 'Cinder::Db::Mysql':
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  cluster_id    => 'localzone',
  collate       => 'utf8_general_ci',
  dbname        => 'cinder',
  host          => '127.0.0.1',
  name          => 'Cinder::Db::Mysql',
  password      => 'trj609V8',
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

database_grant { 'cinder@node-125/cinder':
  name       => 'cinder@node-125/cinder',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[cinder@node-125]',
}

database_user { 'cinder@%':
  name          => 'cinder@%',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  provider      => 'mysql',
  require       => 'Database[cinder]',
}

database_user { 'cinder@127.0.0.1':
  ensure        => 'present',
  name          => 'cinder@127.0.0.1',
  password_hash => '*5E31F32D6A9A14F53096B1FB7617A379C72BC11D',
  provider      => 'mysql',
  require       => 'Database[cinder]',
}

database_user { 'cinder@localhost':
  name          => 'cinder@localhost',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  provider      => 'mysql',
  require       => 'Database[cinder]',
}

database_user { 'cinder@node-125':
  name          => 'cinder@node-125',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  provider      => 'mysql',
  require       => 'Database[cinder]',
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

mysql::db { 'cinder':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'cinder',
  password    => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_%':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_%',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_127.0.0.1':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_127.0.0.1',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_localhost':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_localhost',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql::host_access { 'cinder_node-125':
  database      => 'cinder',
  mysql_module  => '0.3',
  name          => 'cinder_node-125',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
  privileges    => 'ALL',
  user          => 'cinder',
}

openstacklib::db::mysql { 'cinder':
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'cinder',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'cinder',
  password_hash => '*8EF5FEDF8B045EAE21D0A9FA39F5E08F8C66CC8A',
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

