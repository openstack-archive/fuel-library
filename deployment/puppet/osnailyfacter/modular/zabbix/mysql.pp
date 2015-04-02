notice('MODULAR: zabbix-mysql.pp')

include galera::params

class { 'mysql::server':
  config_hash => {
  # Setting root pw breaks everything on puppet 3
  #'root_password' => $zabbix::params::db_root_password,
    'bind_address' => '0.0.0.0',
  },
  client_package_name => $::galera::params::mysql_client_name,
  package_name        => $::galera::params::mysql_server_name,
  enabled             => true,
  wait_timeout        => '86400',
}
