class zabbix::server::db {
  #stub for multiple possible db backends
  anchor { 'zabbix_mysql_start': } ->
  class { 'zabbix::db::mysql': } ->
  anchor { 'zabbix_mysql_end': }
}
