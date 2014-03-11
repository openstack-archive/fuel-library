class zabbix {
  $enabled  = ! empty(get_server_by_role($::fuel_settings['nodes'], 'zabbix-server'))
  if has_key($::fuel_settings, 'zabbix') and $enabled {
    include zabbix::params
    if $::zabbix::params::server {
      class {'zabbix::server': }
    }
  }
}
