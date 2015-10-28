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
  db_host     => '192.168.0.2',
  db_password => 'Lz18BpbQ',
  db_user     => 'root',
  name        => 'Osnailyfacter::Mysql_access',
}

class { 'Sahara::Api':
  name => 'Sahara::Api',
}

class { 'Sahara::Db::Mysql':
  allowed_hosts => ['node-128', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'sahara',
  host          => '127.0.0.1',
  name          => 'Sahara::Db::Mysql',
  password      => 'f0jl4v47',
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

database_grant { 'sahara@node-128/sahara':
  name       => 'sahara@node-128/sahara',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[sahara@node-128]',
}

database_user { 'sahara@%':
  name          => 'sahara@%',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  provider      => 'mysql',
  require       => 'Database[sahara]',
}

database_user { 'sahara@127.0.0.1':
  ensure        => 'present',
  name          => 'sahara@127.0.0.1',
  password_hash => '*E23B25A0B05249B49498D71CFC06EA7453579E1F',
  provider      => 'mysql',
  require       => 'Database[sahara]',
}

database_user { 'sahara@localhost':
  name          => 'sahara@localhost',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  provider      => 'mysql',
  require       => 'Database[sahara]',
}

database_user { 'sahara@node-128':
  name          => 'sahara@node-128',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  provider      => 'mysql',
  require       => 'Database[sahara]',
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

mysql::db { 'sahara':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'sahara',
  password    => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_%':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_%',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_127.0.0.1':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_127.0.0.1',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_localhost':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_localhost',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql::host_access { 'sahara_node-128':
  database      => 'sahara',
  mysql_module  => '0.3',
  name          => 'sahara_node-128',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
  privileges    => 'ALL',
  user          => 'sahara',
}

openstacklib::db::mysql { 'sahara':
  allowed_hosts => ['node-128', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'sahara',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'sahara',
  password_hash => '*574B0AEBFC05252FE7513EFEAE0EBB5C30CF1CCA',
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

