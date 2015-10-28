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
  password      => 'R7CwXDC1rgSbz6z0oL38xb4S',
  user          => 'neutron',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Neutron::Db::Mysql]',
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
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@127.0.0.1':
  ensure        => 'present',
  name          => 'neutron@127.0.0.1',
  password_hash => '*11005BB02C7B249C9E1F7D5EDF70811C80994C41',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@localhost':
  name          => 'neutron@localhost',
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  provider      => 'mysql',
  require       => 'Database[neutron]',
}

database_user { 'neutron@node-1':
  name          => 'neutron@node-1',
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  provider      => 'mysql',
  require       => 'Database[neutron]',
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

mysql::db { 'neutron':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'neutron',
  password    => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_%':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_%',
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_127.0.0.1':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_127.0.0.1',
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_localhost':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_localhost',
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
  privileges    => 'ALL',
  user          => 'neutron',
}

openstacklib::db::mysql::host_access { 'neutron_node-1':
  database      => 'neutron',
  mysql_module  => '0.3',
  name          => 'neutron_node-1',
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
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
  password_hash => '*BF385430F6476AF8DDB084736C33E5BD45765EAD',
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

