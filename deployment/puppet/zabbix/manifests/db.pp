class zabbix::db(
  $db_ip,
  $db_password = 'zabbix',
  $sync_db = false
) {
  #stub for multiple possible db backends
  class { 'zabbix::db::mysql':
    db_ip       => $db_ip,
    db_password => $db_password,
    sync_db     => $sync_db,
  }
  anchor { 'zabbix_mysql_start': } -> Class['zabbix::db::mysql'] -> anchor { 'zabbix_mysql_end': }
}
