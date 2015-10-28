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
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  name          => 'Nova::Db::Mysql',
  password      => '2upYv98H',
  user          => 'nova',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Nova::Db::Mysql]',
  db_host     => '10.108.2.2',
  db_password => 'NDG84Pcc',
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

database_grant { 'nova@node-1/nova':
  name       => 'nova@node-1/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@node-1]',
}

database_user { 'nova@%':
  name          => 'nova@%',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@127.0.0.1':
  ensure        => 'present',
  name          => 'nova@127.0.0.1',
  password_hash => '*18985F3C00080E9D0BFA80095A79F856A936DC88',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@localhost':
  name          => 'nova@localhost',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@node-1':
  name          => 'nova@node-1',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

file { '10.108.2.2-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = 'NDG84Pcc'
host     = '10.108.2.2'

[client]
user     = 'root'
password = 'NDG84Pcc'
host     = '10.108.2.2'

[mysqldump]
user     = 'root'
password = 'NDG84Pcc'
host     = '10.108.2.2'

[mysqladmin]
user     = 'root'
password = 'NDG84Pcc'
host     = '10.108.2.2'

[mysqlcheck]
user     = 'root'
password = 'NDG84Pcc'
host     = '10.108.2.2'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.10.108.2.2.cnf',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.10.108.2.2.cnf',
}

mysql::db { 'nova':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'nova',
  password    => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_%':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_%',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_127.0.0.1':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_127.0.0.1',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_localhost':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_localhost',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_node-1':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_node-1',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql { 'nova':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'nova',
  password_hash => '*CEA846A17B5516D8E8A98A960D4E124963F88B11',
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

