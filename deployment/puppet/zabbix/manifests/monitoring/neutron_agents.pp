class zabbix::monitoring::neutron_agents inherits zabbix::params {
  $neutron = hiera('use_neutron')
  $enabled = $neutron and ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    # Neutron OVS agent
    zabbix_template_link { "${host_name} Template App OpenStack Neutron OVS Agent":
      host     => $host_name,
      template => 'Template App OpenStack Neutron OVS Agent',
      api      => $api_hash,
    }

    # Neutron Metadata agent
    zabbix_template_link { "${host_name} Template App OpenStack Neutron Metadata Agent":
      host     => $host_name,
      template => 'Template App OpenStack Neutron Metadata Agent',
      api      => $api_hash,
    }

    # Neutron L3 agent
    zabbix_template_link { "${host_name} Template App OpenStack Neutron L3 Agent":
      host     => $host_name,
      template => 'Template App OpenStack Neutron L3 Agent',
      api      => $api_hash,
    }

    # Neutron DHCP agent
    zabbix_template_link { "${host_name} Template App OpenStack Neutron DHCP Agent":
      host     => $host_name,
      template => 'Template App OpenStack Neutron DHCP Agent',
      api      => $api_hash,
    }
  }

}
