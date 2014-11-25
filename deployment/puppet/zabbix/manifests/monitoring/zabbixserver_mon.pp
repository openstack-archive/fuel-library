class zabbix::monitoring::zabbixserver_mon {

  if defined_in_state(Class['zabbix::server']) {
    zabbix_template_link { "$zabbix::params::host_name Template App Zabbix Server":
      host => $zabbix::params::host_name,
      template => 'Template App Zabbix Server',
      api => $zabbix::monitoring::api_hash,
    }
  }

}
