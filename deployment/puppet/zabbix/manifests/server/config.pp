class zabbix::server::config {

  include zabbix::params

  zabbix_hostgroup { $zabbix::params::host_groups:
    ensure => present,
    api    => $zabbix::params::api_hash,
  }

  file { '/etc/zabbix/import':
    ensure    => directory,
    recurse   => true,
    purge     => true,
    force     => true,
    source    => 'puppet:///modules/zabbix/import'
  }

  Zabbix_configuration_import { require  => File['/etc/zabbix/import'] }

  zabbix_configuration_import { 'Template_App_Zabbix_Agent.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_Zabbix_Agent.xml',
    api => $zabbix::params::api_hash,
  }

  zabbix_configuration_import { 'Template_Fuel_OS_Linux.xml Import':
    ensure   => present,
    api => $zabbix::params::api_hash,
    xml_file => '/etc/zabbix/import/Template_Fuel_OS_Linux.xml',
  }

}
