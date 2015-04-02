class zabbix::monitoring::swift inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Swift Account":
      host     => $host_name,
      template => 'Template App OpenStack Swift Account',
      api      => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Swift Container":
      host     => $host_name,
      template => 'Template App OpenStack Swift Container',
      api      => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Swift Object":
      host     => $host_name,
      template => 'Template App OpenStack Swift Object',
      api      => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Swift Proxy":
      host     => $host_name,
      template => 'Template App OpenStack Swift Proxy',
      api      => $api_hash,
    }

  }

}
