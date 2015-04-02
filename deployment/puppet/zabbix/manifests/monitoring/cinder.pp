class zabbix::monitoring::cinder inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Cinder API":
      host => $host_name,
      template => 'Template App OpenStack Cinder API',
      api => $api_hash,
    }
    zabbix_template_link { "${host_name} Template App OpenStack Cinder API check":
      host    => $host_name,
      template => 'Template App OpenStack Cinder API check',
      api => $api_hash,
    }
    zabbix::agent::userparameter {
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${host_ip} 8776";
    }

    zabbix_template_link { "${host_name} Template App OpenStack Cinder Scheduler":
      host => $host_name,
      template => 'Template App OpenStack Cinder Scheduler',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Cinder Volume":
      host => $host_name,
      template => 'Template App OpenStack Cinder Volume',
      api => $api_hash,
    }
  }
}
