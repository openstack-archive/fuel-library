class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Murano::Api':
  name => 'Murano::Api',
}

class { 'Murano::Db::Mysql':
  allowed_hosts => ['node-128', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'murano',
  host          => '127.0.0.1',
  name          => 'Murano::Db::Mysql',
  password      => 'R3SuvZbh',
  user          => 'murano',
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
  before      => 'Class[Murano::Db::Mysql]',
  db_host     => '192.168.0.2',
  db_password => 'Lz18BpbQ',
  db_user     => 'root',
  name        => 'Osnailyfacter::Mysql_access',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

database { 'murano':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'murano',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'murano@%/murano':
  name       => 'murano@%/murano',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[murano@%]',
}

database_grant { 'murano@127.0.0.1/murano':
  name       => 'murano@127.0.0.1/murano',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[murano@127.0.0.1]',
}

database_grant { 'murano@localhost/murano':
  name       => 'murano@localhost/murano',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[murano@localhost]',
}

database_grant { 'murano@node-128/murano':
  name       => 'murano@node-128/murano',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[murano@node-128]',
}

database_user { 'murano@%':
  name          => 'murano@%',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  provider      => 'mysql',
  require       => 'Database[murano]',
}

database_user { 'murano@127.0.0.1':
  ensure        => 'present',
  name          => 'murano@127.0.0.1',
  password_hash => '*BCCA78ECEFD928D2ED70C99A4AA81797B7897C68',
  provider      => 'mysql',
  require       => 'Database[murano]',
}

database_user { 'murano@localhost':
  name          => 'murano@localhost',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  provider      => 'mysql',
  require       => 'Database[murano]',
}

database_user { 'murano@node-128':
  name          => 'murano@node-128',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  provider      => 'mysql',
  require       => 'Database[murano]',
}

file { '192.168.0.2-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = 'Lz18BpbQ'
host     = '192.168.0.2'

[client]
user     = 'root'
password = 'Lz18BpbQ'
host     = '192.168.0.2'

[mysqldump]
user     = 'root'
password = 'Lz18BpbQ'
host     = '192.168.0.2'

[mysqladmin]
user     = 'root'
password = 'Lz18BpbQ'
host     = '192.168.0.2'

[mysqlcheck]
user     = 'root'
password = 'Lz18BpbQ'
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

mysql::db { 'murano':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'murano',
  password    => '*2D73D96F87074287A16431E7763D11667903E2BA',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'murano',
}

openstacklib::db::mysql::host_access { 'murano_%':
  database      => 'murano',
  mysql_module  => '0.3',
  name          => 'murano_%',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  privileges    => 'ALL',
  user          => 'murano',
}

openstacklib::db::mysql::host_access { 'murano_127.0.0.1':
  database      => 'murano',
  mysql_module  => '0.3',
  name          => 'murano_127.0.0.1',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  privileges    => 'ALL',
  user          => 'murano',
}

openstacklib::db::mysql::host_access { 'murano_localhost':
  database      => 'murano',
  mysql_module  => '0.3',
  name          => 'murano_localhost',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  privileges    => 'ALL',
  user          => 'murano',
}

openstacklib::db::mysql::host_access { 'murano_node-128':
  database      => 'murano',
  mysql_module  => '0.3',
  name          => 'murano_node-128',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  privileges    => 'ALL',
  user          => 'murano',
}

openstacklib::db::mysql { 'murano':
  allowed_hosts => ['node-128', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'murano',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'murano',
  password_hash => '*2D73D96F87074287A16431E7763D11667903E2BA',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'murano',
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

