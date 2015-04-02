class zabbix::monitoring::zabbix_server inherits zabbix::params {
  $enabled = $server

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App Zabbix Server":
      host => $host_name,
      template => 'Template App Zabbix Server',
      api => $api_hash,
    }

  }

}
