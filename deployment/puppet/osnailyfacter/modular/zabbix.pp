include galera::params
class { 'zabbix':
  mysql_server_pkg => $galera::params::mysql_server_name,
}
