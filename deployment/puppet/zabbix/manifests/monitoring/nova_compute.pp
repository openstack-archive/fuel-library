class zabbix::monitoring::nova_compute inherits zabbix::params {
  $enabled = ($role  == 'compute')
  $neutron = hiera('use_neutron')

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    #Metadata api
    if ! $neutron {
      zabbix_template_link { "${host_name} Template App OpenStack Nova API Metadata":
        host => $host_name,
        template => 'Template App OpenStack Nova API Metadata',
        api => $api_hash,
      }
    }

    #Nova compute
    zabbix_template_link { "${host_name} Template App OpenStack Nova Compute":
      host => $host_name,
      template => 'Template App OpenStack Nova Compute',
      api => $api_hash,
    }

    #Libvirt
    zabbix_template_link { "${host_name} Template App OpenStack Libvirt":
      host => $host_name,
      template => 'Template App OpenStack Libvirt',
      api => $api_hash,
    }

  }

}
