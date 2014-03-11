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

  # RabbitMQ templates
  zabbix_configuration_import { 'Template_App_OpenStack_RabbitMQ.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_RabbitMQ.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_RabbitMQ_ha.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_RabbitMQ_ha.xml',
    api => $zabbix::params::api_hash,
  }

  # Horizon
  zabbix_configuration_import { 'Template_App_OpenStack_Horizon.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Horizon.xml',
    api => $zabbix::params::api_hash,
  }

  # MySQL
  zabbix_configuration_import { 'Template_App_MySQL.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_MySQL.xml',
    api => $zabbix::params::api_hash,
  }

  # memcached
  zabbix_configuration_import { 'Template_App_Memcache.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_Memcache.xml',
    api => $zabbix::params::api_hash,
  }

  # HAProxy
  zabbix_configuration_import { 'Template_App_HAProxy.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_HAProxy.xml',
    api => $zabbix::params::api_hash,
  }

  # Firewall
  zabbix_configuration_import { 'Template_App_Iptables_Stats.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_Iptables_Stats.xml',
    api => $zabbix::params::api_hash,
  }

  # Zabbix server
  zabbix_configuration_import { 'Template_App_Zabbix_Server.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_Zabbix_Server.xml',
    api => $zabbix::params::api_hash,
  }

  # Virtual OpenStack Cluster
  zabbix_configuration_import { 'Template_OpenStack_Cluster.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_OpenStack_Cluster.xml',
    api => $zabbix::params::api_hash,
  }

  # Neutron
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_Server.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_Server.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_OVS_Agent.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_OVS_Agent.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_Metadata_Agent.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_Metadata_Agent.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_L3_Agent.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_L3_Agent.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_DHCP_Agent.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_DHCP_Agent.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_API.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_API.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Neutron_API_check.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_API_check.xml',
    api => $zabbix::params::api_hash,
  }
  
  # Open vSwitch
  zabbix_configuration_import { 'Template_App_OpenStack_Open_vSwitch.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Open_vSwitch.xml',
    api => $zabbix::params::api_hash,
  }
  
  # Ceilometer
  zabbix_configuration_import { 'Template_App_OpenStack_Ceilometer.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Ceilometer.xml',
    api => $zabbix::params::api_hash,
  }
  zabbix_configuration_import { 'Template_App_OpenStack_Ceilometer_Compute.xml Import':
    ensure   => present,
    xml_file => '/etc/zabbix/import/Template_App_OpenStack_Ceilometer_Compute.xml',
    api => $zabbix::params::api_hash,
  }
}
