class zabbix::monitoring::swift_mon {

  include zabbix::params

  #Swift
  if defined_in_state(Class['openstack::swift::storage_node']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Account":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Account',
      api => $zabbix::monitoring::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Container":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Container',
      api => $zabbix::monitoring::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Object":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Object',
      api => $zabbix::monitoring::api_hash,
    }
  }

  if defined_in_state(Class['swift::proxy']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Proxy":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Proxy',
      api => $zabbix::monitoring::api_hash,
    }
  }
}
