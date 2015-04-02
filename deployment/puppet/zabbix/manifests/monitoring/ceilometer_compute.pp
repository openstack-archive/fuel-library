class zabbix::monitoring::ceilometer_compute inherits zabbix::params {
  $ceilometer = hiera('ceilometer')
  $enabled = ($role in ['compute']) and ($ceilometer['enabled'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Ceilometer Compute":
      host => $host_name,
      template => 'Template App OpenStack Ceilometer Compute',
      api => $api_hash,
    }
  }
}
