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

  # Nova templates
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_EC2.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_EC2.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_API.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_Metadata.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_Metadata.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_OSAPI.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_OSAPI.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_OSAPI_check.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_OSAPI_check.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_Cert.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Cert.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_ConsoleAuth.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_ConsoleAuth.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_Scheduler.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Scheduler.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_Compute.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Compute.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Libvirt.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Libvirt.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Nova_Network.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Network.xml',
    api => $zabbix::params::api_hash,
  }

  # Keystone templates
  zabbix_configuration_import { 'Template_App_OpenStack_Keystone.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Keystone.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Keystone_API_check.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Keystone_API_check.xml',
    api => $zabbix::params::api_hash,
  }

  # Glance templates
  zabbix_configuration_import { 'Template_App_OpenStack_Glance_API.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_API.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Glance_API_check.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_API_check.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Glance_Registry.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_Registry.xml',
    api => $zabbix::params::api_hash,
  }

  # Cinder templates
  zabbix_configuration_import { 'Template_App_OpenStack_Cinder_API.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_API.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Cinder_API_check.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_API_check.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Cinder_Scheduler.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_Scheduler.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Cinder_Volume.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_Volume.xml',
    api => $zabbix::params::api_hash,
  }

  # Swift templates
  zabbix_configuration_import { 'Template_App_OpenStack_Swift_Account.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Account.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Swift_Container.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Container.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Swift_Object.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Object.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Swift_Proxy.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Proxy.xml',
    api => $zabbix::params::api_hash,
  }
}
