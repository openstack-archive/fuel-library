class zabbix::monitoring::openvswitch inherits zabbix::params {
  $enabled = true

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    # Open vSwitch
    zabbix_template_link { "${host_name} Template App OpenStack Open vSwitch":
      host     => $host_name,
      template => 'Template App OpenStack Open vSwitch',
      api      => $api_hash,
    }
  }

}
