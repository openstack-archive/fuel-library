class zabbix::monitoring::neutron_server inherits zabbix::params {
  $neutron = hiera('use_neutron')
  $enabled = $neutron and ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Neutron Server":
      host => $host_name,
      template => 'Template App OpenStack Neutron Server',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Neutron API check":
      host    => $host_name,
      template => 'Template App OpenStack Neutron API check',
      api => $api_hash,
    }

    zabbix::agent::userparameter {
      'neutron.api.status':
        command => "/etc/zabbix/scripts/check_api.py neutron http ${host_ip} 9696";
    }

  }

}
