class zabbix inherits zabbix::params {

  if $zabbix_enabled {
    if $server {
      notice('Zabbix Server')

      anchor { 'zabbix_server_start' :} ->
      class { 'zabbix::server' :} ->
      anchor { 'zabbix_server_end' :}

      anchor { 'zabbix_agent_start': } ->
      class { 'zabbix::agent': } ->
      anchor { 'zabbix_agent_end': }

      Anchor['zabbix_server_end'] ->
      Anchor['zabbix_agent_start']

    } else {
      notice('Zabbix Client')
      class { 'zabbix::agent': }
    }
  }
}
