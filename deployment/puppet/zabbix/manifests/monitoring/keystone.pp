class zabbix::monitoring::keystone inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Keystone":
      host => $host_name,
      template => 'Template App OpenStack Keystone',
      api => $api_hash,
    }
    zabbix_template_link { "${host_name} Template App OpenStack Keystone API check":
      host    => $host_name,
      template => 'Template App OpenStack Keystone API check',
      api => $api_hash,
    }
    zabbix::agent::userparameter {
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${host_ip} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${host_ip} 35357";
    }
  }
}
