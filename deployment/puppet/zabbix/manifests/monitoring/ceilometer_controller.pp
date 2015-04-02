class zabbix::monitoring::ceilometer_controller inherits zabbix::params {
  $ceilometer = hiera('ceilometer')
  $enabled = ($role in ['controller', 'primary-controller']) and ($ceilometer['enabled'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Ceilometer":
      host => $host_name,
      template => 'Template App OpenStack Ceilometer',
      api => $api_hash,
    }
  }
}
