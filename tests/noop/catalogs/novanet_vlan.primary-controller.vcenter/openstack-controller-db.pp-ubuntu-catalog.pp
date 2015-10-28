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
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  name          => 'Nova::Db::Mysql',
  password      => 'owRNCV7f',
  user          => 'nova',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Nova::Db::Mysql]',
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

database_grant { 'nova@node-3/nova':
  name       => 'nova@node-3/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@node-3]',
}

database_user { 'nova@%':
  name          => 'nova@%',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@127.0.0.1':
  ensure        => 'present',
  name          => 'nova@127.0.0.1',
  password_hash => '*948194C0B1D7ABCC61CD75AA12568FE2EB57DEEE',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@localhost':
  name          => 'nova@localhost',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@node-3':
  name          => 'nova@node-3',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  provider      => 'mysql',
  require       => 'Database[nova]',
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

mysql::db { 'nova':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'nova',
  password    => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_%':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_%',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_127.0.0.1':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_127.0.0.1',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_localhost':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_localhost',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_node-3':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_node-3',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql { 'nova':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'nova',
  password_hash => '*35165BC272CC63648C6144B2FBFC57D4B79C154B',
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

