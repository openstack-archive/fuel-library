class zabbix inherits zabbix::params {

  if $zabbix_enabled {
    if $server {
      notice('Zabbix Server')

      anchor { 'zabbix_server_start' :} ->
      class { 'zabbix::server' :} ->
      anchor { 'zabbix_server_end' :}

      anchor { 'zabbix_monitoring_start': } ->
      class { 'zabbix::monitoring': } ->
      anchor { 'zabbix_monitoring_end': }

      Anchor['zabbix_server_end'] ->
      Anchor['zabbix_monitoring_start']

    } else {
      notice('Zabbix Client')
      class { 'zabbix::monitoring': }
    }
  }
}
