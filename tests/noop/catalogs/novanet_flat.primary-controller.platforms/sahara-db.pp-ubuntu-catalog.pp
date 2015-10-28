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
  before      => 'Class[Sahara::Db::Mysql]',
  db_host     => '10.108.2.2',
  db_password => 'NDG84Pcc',
  db_user     => 'root',
  name        => 'Osnailyfacter::Mysql_access',
}

class { 'Sahara::Api':
  name => 'Sahara::Api',
}

class { 'Sahara::Db::Mysql':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'sahara',
  host          => '127.0.0.1',
  name          => 'Sahara::Db::Mysql',
  password      => 'LwV220yW',
  user          => 'sahara',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

database { 'sahara':
  ensure   => 'present',
  charset  => 'utf8',
  name     => 'sahara',
  provider => 'mysql',
  require  => 'Class[Mysql::Server]',
}

database_grant { 'sahara@%/sahara':
  name       => 'sahara@%/sahara',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[sahara@%]',
}

database_grant { 'sahara@127.0.0.1/sahara':
  name       => 'sahara@127.0.0.1/sahara',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[sahara@127.0.0.1]',
}

database_grant { 'sahara@localhost/sahara':
  name       => 'sahara@localhost/sahara',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[sahara@localhost]',
}

database_grant { 'sahara@node-1/sahara':
  name       => 'sahara@node-1/sahara',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[sahara@node-1]',
}

database_user { 'sahara@%':
  name          => 'sahara@%',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  provider      => 'mysql',
  require       => 'Database[sahara]',
}

database_user { 'sahara@127.0.0.1':
  ensure        => 'present',
  name          => 'sahara@127.0.0.1',
  password_hash => '*AA408877BBD7431A75193B5D79A09335BCF1E4FE',
  provider      => 'mysql',
  require       => 'Database[sahara]',
}

database_user { 'sahara@localhost':
  name          => 'sahara@localhost',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  provider      => 'mysql',
  require       => 'Database[sahara]',
}

database_user { 'sahara@node-1':
  name          => 'sahara@node-1',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  provider      => 'mysql',
  require       => 'Database[sahara]',
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

mysql::db { 'sahara':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'sahara',
  password    => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_%':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_%',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_127.0.0.1':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_127.0.0.1',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_localhost':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_localhost',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_node-1':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_node-1',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql { 'sahara':
  allowed_hosts => ['node-1', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'sahara',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'sahara',
  password_hash => '*85232FC6B0733A3BD5F0799D6BF97D1DA93033FF',
  privileges    => 'ALL',
  require       => 'Class[Mysql::Python]',
  user          => 'sahara',
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

