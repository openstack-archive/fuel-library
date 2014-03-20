class zabbix::monitoring::keystone_mon {

  include zabbix::params

  #Keystone
  if defined(Class['keystone']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Keystone":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Keystone',
      api => $zabbix::params::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Keystone API check":
      host    => $zabbix::params::host_name,
      template => 'Template App OpenStack Keystone API check',
      api => $zabbix::params::api_hash,
    }
    zabbix::agent::userparameter {
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${::internal_address} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${::internal_address} 35357";
    }
  }
}
