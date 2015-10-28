class { 'Galera::Client':
  before             => 'Class[Osnailyfacter::Mysql_access]',
  custom_setup_class => 'galera',
  name               => 'Galera::Client',
}

class { 'Keystone::Db::Mysql':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'keystone',
  host          => '127.0.0.1',
  name          => 'Keystone::Db::Mysql',
  password      => 'RGAv0zS2',
  user          => 'keystone',
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
  before      => 'Class[Keystone::Db::Mysql]',
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

database { 'keystone':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'keystone',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'keystone@%/keystone':
  name       => 'keystone@%/keystone',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[keystone@%]',
}

database_grant { 'keystone@127.0.0.1/keystone':
  name       => 'keystone@127.0.0.1/keystone',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[keystone@127.0.0.1]',
}

database_grant { 'keystone@localhost/keystone':
  name       => 'keystone@localhost/keystone',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[keystone@localhost]',
}

database_grant { 'keystone@node-3/keystone':
  name       => 'keystone@node-3/keystone',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[keystone@node-3]',
}

database_user { 'keystone@%':
  name          => 'keystone@%',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  provider      => 'mysql',
  require       => 'Database[keystone]',
}

database_user { 'keystone@127.0.0.1':
  ensure        => 'present',
  name          => 'keystone@127.0.0.1',
  password_hash => '*A21F5F94C2C0EDD8064AA1DD1A814DA30A579135',
  provider      => 'mysql',
  require       => 'Database[keystone]',
}

database_user { 'keystone@localhost':
  name          => 'keystone@localhost',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  provider      => 'mysql',
  require       => 'Database[keystone]',
}

database_user { 'keystone@node-3':
  name          => 'keystone@node-3',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  provider      => 'mysql',
  require       => 'Database[keystone]',
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

mysql::db { 'keystone':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'keystone',
  password    => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'keystone',
}

openstacklib::db::mysql::host_access { 'keystone_%':
  database      => 'keystone',
  mysql_module  => '0.3',
  name          => 'keystone_%',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  privileges    => 'ALL',
  user          => 'keystone',
}

openstacklib::db::mysql::host_access { 'keystone_127.0.0.1':
  database      => 'keystone',
  mysql_module  => '0.3',
  name          => 'keystone_127.0.0.1',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  privileges    => 'ALL',
  user          => 'keystone',
}

openstacklib::db::mysql::host_access { 'keystone_localhost':
  database      => 'keystone',
  mysql_module  => '0.3',
  name          => 'keystone_localhost',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  privileges    => 'ALL',
  user          => 'keystone',
}

openstacklib::db::mysql::host_access { 'keystone_node-3':
  database      => 'keystone',
  mysql_module  => '0.3',
  name          => 'keystone_node-3',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  privileges    => 'ALL',
  user          => 'keystone',
}

openstacklib::db::mysql { 'keystone':
  allowed_hosts => ['node-3', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'keystone',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'keystone',
  password_hash => '*964352B8D37BE15D2F35D9C80D032EA78407C693',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'keystone',
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

