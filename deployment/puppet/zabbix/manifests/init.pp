class zabbix {
  if has_key($::fuel_settings, 'zabbix') {
    include zabbix::params
    if $::zabbix::params::enabled {
      if $::zabbix::params::server {
        class {'zabbix::server': }
      }
    }
  }
}
