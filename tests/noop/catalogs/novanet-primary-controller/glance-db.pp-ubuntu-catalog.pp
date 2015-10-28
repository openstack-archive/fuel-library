class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Glance::Db::Mysql':
  allowed_hosts => ['node-137', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  cluster_id    => 'localzone',
  collate       => 'utf8_general_ci',
  dbname        => 'glance',
  host          => '127.0.0.1',
  name          => 'Glance::Db::Mysql',
  password      => 's5aslXZn',
  user          => 'glance',
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
  before      => 'Class[Glance::Db::Mysql]',
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

database { 'glance':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'glance',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'glance@%/glance':
  name       => 'glance@%/glance',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[glance@%]',
}

database_grant { 'glance@127.0.0.1/glance':
  name       => 'glance@127.0.0.1/glance',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[glance@127.0.0.1]',
}

database_grant { 'glance@localhost/glance':
  name       => 'glance@localhost/glance',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[glance@localhost]',
}

database_grant { 'glance@node-137/glance':
  name       => 'glance@node-137/glance',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[glance@node-137]',
}

database_user { 'glance@%':
  name          => 'glance@%',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  provider      => 'mysql',
  require       => 'Database[glance]',
}

database_user { 'glance@127.0.0.1':
  ensure        => 'present',
  name          => 'glance@127.0.0.1',
  password_hash => '*12DA47C8DE41C6FC2C8894FAF8D66FDF3A163A17',
  provider      => 'mysql',
  require       => 'Database[glance]',
}

database_user { 'glance@localhost':
  name          => 'glance@localhost',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  provider      => 'mysql',
  require       => 'Database[glance]',
}

database_user { 'glance@node-137':
  name          => 'glance@node-137',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  provider      => 'mysql',
  require       => 'Database[glance]',
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

mysql::db { 'glance':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'glance',
  password    => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'glance',
}

openstacklib::db::mysql::host_access { 'glance_%':
  database      => 'glance',
  mysql_module  => '0.3',
  name          => 'glance_%',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  privileges    => 'ALL',
  user          => 'glance',
}

openstacklib::db::mysql::host_access { 'glance_127.0.0.1':
  database      => 'glance',
  mysql_module  => '0.3',
  name          => 'glance_127.0.0.1',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  privileges    => 'ALL',
  user          => 'glance',
}

openstacklib::db::mysql::host_access { 'glance_localhost':
  database      => 'glance',
  mysql_module  => '0.3',
  name          => 'glance_localhost',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  privileges    => 'ALL',
  user          => 'glance',
}

openstacklib::db::mysql::host_access { 'glance_node-137':
  database      => 'glance',
  mysql_module  => '0.3',
  name          => 'glance_node-137',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  privileges    => 'ALL',
  user          => 'glance',
}

openstacklib::db::mysql { 'glance':
  allowed_hosts => ['node-137', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'glance',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'glance',
  password_hash => '*5DA0767C5C7B2248DFD5EDEB9096C600EE851917',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'glance',
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

