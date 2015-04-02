class zabbix::monitoring::horizon inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Horizon":
      host => $host_name,
      template => 'Template App OpenStack Horizon',
      api => $api_hash,
    }
  }
}
