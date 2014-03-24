class zabbix::monitoring::neutron_mon {

  include zabbix::params

  # Neutron server
  if defined(Class['::neutron']) and !defined(Class['openstack::compute']) {

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron Server":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron Server',
      api => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron API":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron API',
      api => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron API check":
      host    => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron API check',
      api => $zabbix::params::api_hash,
    }

    zabbix::agent::userparameter {
      'neutron.api.status':
        command => "/etc/zabbix/scripts/check_api.py neutron http ${::internal_address} 9696";
    }
  }

  # Neutron OVS agent
  if defined(Class['::neutron::agents::ovs']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron OVS Agent":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron OVS Agent',
      api => $zabbix::params::api_hash,
    }
  }

  # Neutron Metadata agent
  if defined(Class['::neutron::agents::metadata']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron Metadata Agent":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron Metadata Agent',
      api => $zabbix::params::api_hash,
    }
  }

  # Neutron L3 agent
  if defined(Class['::neutron::agents::l3']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron L3 Agent":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron L3 Agent',
      api => $zabbix::params::api_hash,
    }
  }

  # Neutron DHCP agent
  if defined(Class['::neutron::agents::dhcp']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Neutron DHCP Agent":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Neutron DHCP Agent',
      api => $zabbix::params::api_hash,
    }
  }
}
