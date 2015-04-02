class zabbix::monitoring::nova_controller inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])
  $neutron = hiera('use_neutron')

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Nova API":
      host => $host_name,
      template => 'Template App OpenStack Nova API',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Nova API OSAPI":
      host => $host_name,
      template => 'Template App OpenStack Nova API OSAPI',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Nova API OSAPI check":
      host    => $host_name,
      template => 'Template App OpenStack Nova API OSAPI check',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Nova API EC2":
      host => $host_name,
      template => 'Template App OpenStack Nova API EC2',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Nova Cert":
      host => $host_name,
      template => 'Template App OpenStack Nova Cert',
      api => $api_hash,
    }

    zabbix::agent::userparameter {
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::internal_address} 8774";
    }

    if ! $neutron {
      zabbix_template_link { "${host_name} Template App OpenStack Nova Network":
        host => $host_name,
        template => 'Template App OpenStack Nova Network',
        api => $api_hash,
      }
    }

    zabbix_template_link { "${host_name} Template App OpenStack Nova ConsoleAuth":
      host => $host_name,
      template => 'Template App OpenStack Nova ConsoleAuth',
      api => $api_hash,
    }

    zabbix_template_link { "${host_name} Template App OpenStack Nova Scheduler":
      host => $host_name,
      template => 'Template App OpenStack Nova Scheduler',
      api => $api_hash,
    }

  }

}
