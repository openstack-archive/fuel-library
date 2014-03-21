class zabbix::monitoring::swift_mon {

  include zabbix::params

  #Swift
  if defined(Class['openstack::swift::storage_node']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Account":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Account',
      api => $zabbix::params::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Container":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Container',
      api => $zabbix::params::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Object":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Object',
      api => $zabbix::params::api_hash,
    }
  }

  if defined(Class['swift::proxy']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Swift Proxy":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Swift Proxy',
      api => $zabbix::params::api_hash,
    }
  }
}
