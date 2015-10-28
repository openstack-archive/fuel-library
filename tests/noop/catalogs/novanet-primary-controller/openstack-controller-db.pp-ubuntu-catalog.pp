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

class { 'Nova::Db::Mysql':
  allowed_hosts => ['node-137', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  name          => 'Nova::Db::Mysql',
  password      => 'aAU4jYDt',
  user          => 'nova',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Nova::Db::Mysql]',
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

database { 'nova':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'nova',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'nova@%/nova':
  name       => 'nova@%/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@%]',
}

database_grant { 'nova@127.0.0.1/nova':
  name       => 'nova@127.0.0.1/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@127.0.0.1]',
}

database_grant { 'nova@localhost/nova':
  name       => 'nova@localhost/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@localhost]',
}

database_grant { 'nova@node-137/nova':
  name       => 'nova@node-137/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@node-137]',
}

database_user { 'nova@%':
  name          => 'nova@%',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@127.0.0.1':
  ensure        => 'present',
  name          => 'nova@127.0.0.1',
  password_hash => '*3279C183DA56A87B8242378B329B66A1BEB0579B',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@localhost':
  name          => 'nova@localhost',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@node-137':
  name          => 'nova@node-137',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  provider      => 'mysql',
  require       => 'Database[nova]',
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

mysql::db { 'nova':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'nova',
  password    => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_%':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_%',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_127.0.0.1':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_127.0.0.1',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_localhost':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_localhost',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_node-137':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_node-137',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql { 'nova':
  allowed_hosts => ['node-137', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'nova',
  password_hash => '*5E55C5589158CDFF7C6746624160CDE8CDBC59CC',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'nova',
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

