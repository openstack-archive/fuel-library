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
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  name          => 'Nova::Db::Mysql',
  password      => 'VXcP6cIR',
  user          => 'nova',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  before      => 'Class[Nova::Db::Mysql]',
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

database_grant { 'nova@node-125/nova':
  name       => 'nova@node-125/nova',
  privileges => 'all',
  provider   => 'mysql',
  require    => 'Database_user[nova@node-125]',
}

database_user { 'nova@%':
  name          => 'nova@%',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@127.0.0.1':
  ensure        => 'present',
  name          => 'nova@127.0.0.1',
  password_hash => '*4116E6B2C7DC62014D9F5F04A456B181987418DA',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@localhost':
  name          => 'nova@localhost',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  provider      => 'mysql',
  require       => 'Database[nova]',
}

database_user { 'nova@node-125':
  name          => 'nova@node-125',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  provider      => 'mysql',
  require       => 'Database[nova]',
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

mysql::db { 'nova':
  charset     => 'utf8',
  enforce_sql => 'false',
  grant       => 'all',
  host        => '127.0.0.1',
  name        => 'nova',
  password    => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  require     => 'Class[Mysql::Config]',
  sql         => '',
  user        => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_%':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_%',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_127.0.0.1':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_127.0.0.1',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_localhost':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_localhost',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql::host_access { 'nova_node-125':
  database      => 'nova',
  mysql_module  => '0.3',
  name          => 'nova_node-125',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
  privileges    => 'ALL',
  user          => 'nova',
}

openstacklib::db::mysql { 'nova':
  allowed_hosts => ['node-125', 'localhost', '127.0.0.1', '%'],
  charset       => 'utf8',
  collate       => 'utf8_general_ci',
  dbname        => 'nova',
  host          => '127.0.0.1',
  mysql_module  => '0.3',
  name          => 'nova',
  password_hash => '*8250B7AAE9BE1658CE353EAAE2A4A65E6EEF5C7E',
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

