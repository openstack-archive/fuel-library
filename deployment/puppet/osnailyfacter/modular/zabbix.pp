include galera::params
class { 'zabbix':
  mysql_server_pkg => $::galera::params::mysql_server_name,
  mysql_client_pkg => $::galera::params::mysql_client_name,
}