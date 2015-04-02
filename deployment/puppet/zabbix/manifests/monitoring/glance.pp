class zabbix::monitoring::glance inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Glance API":
      host => $host_name,
      template => 'Template App OpenStack Glance API',
      api => $api_hash,
    }
    zabbix_template_link { "${host_name} Template App OpenStack Glance API check":
      host    => $host_name,
      template => 'Template App OpenStack Glance API check',
      api => $api_hash,
    }
    zabbix::agent::userparameter {
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${host_ip} 9292";
    }

    zabbix_template_link { "${host_name} Template App OpenStack Glance Registry":
      host => $host_name,
      template => 'Template App OpenStack Glance Registry',
      api => $api_hash,
    }
  }
}
