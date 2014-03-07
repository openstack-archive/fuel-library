class zabbix::monitoring::neutron_mon {

  include zabbix::params

  #OVS server & db
  if defined(Class['quantum::plugins::ovs']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Open vSwitch":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Open vSwitch',
      api => $zabbix::params::api_hash,
    }
  }

  #Quantum Open vSwitch Agent
  if defined(Class['quantum::agents::ovs']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Quantum Agent":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Quantum Agent',
      api => $zabbix::params::api_hash,
    }
  }

  #Quantum server
  if defined(Class['quantum::server']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Quantum Server":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Quantum Server',
      api => $zabbix::params::api_hash,
    }
  }
}
