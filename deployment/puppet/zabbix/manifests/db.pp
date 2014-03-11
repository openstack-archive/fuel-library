class zabbix::db {
  #stub for multiple possible db backends
  class { 'zabbix::db::mysql': }
  anchor { 'zabbix_mysql_start': } -> Class['zabbix::db::mysql'] -> anchor { 'zabbix_mysql_end': }
}
