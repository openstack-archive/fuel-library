class zabbix::monitoring {

  $virtualhost_cluster_fqdn = $zabbix::params::server_hostname
  $virtualhost_cluster_name = "OpenStackCluster${::deployment_id}"

  $access_user          = $::fuel_settings['access']['user']
  $access_password      = $::fuel_settings['access']['password']
  $access_tenant        = $::fuel_settings['access']['tenant']
  $keystone_db_password = $::fuel_settings['keystone']['db_password']
  $nova_db_password     = $::fuel_settings['nova']['db_password']
  $cinder_db_password   = $::fuel_settings['cinder']['db_password']
  $rabbit_password      = $::fuel_settings['rabbit']['password']

#  class {'zabbix::repo': 
#    stage => 'openstack-custom-repo',
#  }

  class { 'zabbix::agent': }

  Zabbix_usermacro { require => [Class['zabbix::agent'], Class['zabbix::api']] }
  Zabbix_template_link { require => [Class['zabbix::agent'], Class['zabbix::api']] }
  Zabbix_host { require => Class['zabbix::api'] }

  zabbix_usermacro { "$::fqdn IP_PUBLIC":
    host  => $::fqdn,
    macro => '{$IP_PUBLIC}',
    value => $::public_address,
    tag => "cluster-${deployment_id}"
  }

  zabbix_usermacro { "$::fqdn IP_MANAGEMENT":
    host  => $::fqdn,
    macro => '{$IP_MANAGEMENT}',
    value => $::internal_address,
    tag => "cluster-${deployment_id}"
  }

  zabbix_usermacro { "$::fqdn IP_STORAGE":
    host  => $::fqdn,
    macro => '{$IP_STORAGE}',
    value => $::storage_address,
    tag => "cluster-${deployment_id}"
  }

  #zabbix scripts - begin

  file { $::zabbix::params::agent_scripts_path:
    ensure    => directory,
    recurse   => true,
    purge     => true,
    force     => true,
    mode      => '0755',
    source    => 'puppet:///modules/zabbix/scripts',
    require   => Package[$zabbix::params::agent_package]
  }

  file { '/etc/zabbix/check_api.conf':
    ensure      => present,
    content     => template('zabbix/check_api.conf.erb'),
    require   => Package[$zabbix::params::agent_package]
  }

  file { '/etc/zabbix/check_rabbit.conf':
    ensure      => present,
    content     => template('zabbix/check_rabbit.conf.erb'),
    require   => Package[$zabbix::params::agent_package]
  }

  file { '/etc/zabbix/check_db.conf':
    ensure      => present,
    content     => template('zabbix/check_db.conf.erb'),
    require   => Package[$zabbix::params::agent_package]
  }
  

  #zabbix scripts - end

  package { 'sudo':
    ensure => present,
  }

 # sudo::directive {'zabbix_no_requiretty':
 #   ensure  => present,
 #   content => 'Defaults:zabbix !requiretty',
 # }

  file {'zabbix_no_requiretty':
    path => '/etc/sudoers.d/zabbix',
    mode => 0440,
    owner => root,
    group => root,
    source => 'puppet:///modules/zabbix/zabbix-sudo',
  }

  #Zabbix Agent
  zabbix_template_link { "$::fqdn Template App Zabbix Agent":
    host => $::fqdn,
    template => 'Template App Zabbix Agent',
    tag => "cluster-${deployment_id}"
  }

  #Puppet Agent
  zabbix_template_link { "$::fqdn Template App Puppet Agent":
    host => $::fqdn,
    template => 'Template App Puppet Agent',
    tag => "cluster-${deployment_id}"
  }

  #Linux
  zabbix_template_link { "$::fqdn Template Fuel OS Linux":
    host => $::fqdn,
    template => 'Template Fuel OS Linux',
    tag => "cluster-${deployment_id}"
  }
  zabbix::agent::userparameter {
    'vfs.dev.discovery':
      ensure => 'present',
      command => '/etc/zabbix/scripts/vfs.dev.discovery.sh';
    'vfs.mdadm.discovery':
      ensure => 'present',
      command => '/etc/zabbix/scripts/vfs.mdadm.discovery.sh';
    'proc.vmstat':
      key => 'proc.vmstat[*]',
      command => 'grep \'$1\' /proc/vmstat | awk \'{print $$2}\''
  }

  #Zabbix server
  if defined(Class['zabbix::server']) {
    require zabbix::frontend
    
    ### TEMPLATE IMPORT - BEGIN

    file { '/etc/zabbix/import':
      ensure    => directory,
      recurse   => true,
      purge     => true,
      force     => true,
      source    => 'puppet:///modules/zabbix/import'
    }

    Zabbix_configuration_import {
      require  => File['/etc/zabbix/import']
    }
    Zabbix_configuration_import <||> -> Zabbix_template_link <||>

    zabbix_configuration_import { 'Template_App_Agentless.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Agentless.xml'
    }
    zabbix_configuration_import { 'Template_App_Elasticsearch_Cluster.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Elasticsearch_Cluster.xml'
    }
    zabbix_configuration_import { 'Template_App_Elasticsearch_Node.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Elasticsearch_Node.xml'
    }
    zabbix_configuration_import { 'Template_App_Elasticsearch_Service.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Elasticsearch_Service.xml'
    }
    zabbix_configuration_import { 'Template_App_HAProxy.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_HAProxy.xml'
    }
    zabbix_configuration_import { 'Template_App_Iptables_Stats.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Iptables_Stats.xml'
    }
    zabbix_configuration_import { 'Template_App_Kibana.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Kibana.xml'
    }
    zabbix_configuration_import { 'Template_App_Logstash_Collector.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Logstash_Collector.xml'
    }
    zabbix_configuration_import { 'Template_App_Logstash_Shipper.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Logstash_Shipper.xml'
    }
    zabbix_configuration_import { 'Template_App_Memcache.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Memcache.xml'
    }
    zabbix_configuration_import { 'Template_App_MySQL.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_MySQL.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_API.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_API.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_API_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_API_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_Scheduler.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_Scheduler.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_Volume.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_Volume.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Glance_API.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_API.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Glance_API_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_API_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Glance_Registry.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_Registry.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Horizon.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Horizon.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Keystone.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Keystone.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Keystone_API_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Keystone_API_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Libvirt.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Libvirt.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_EC2.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_EC2.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_Metadata.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_Metadata.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_OSAPI.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_OSAPI.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_OSAPI_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_OSAPI_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_Cert.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Cert.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_Compute.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Compute.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_ConsoleAuth.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_ConsoleAuth.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_Scheduler.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Scheduler.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Open_vSwitch.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Open_vSwitch.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Quantum_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Quantum_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Quantum_Server.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Quantum_Server.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_RabbitMQ.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_RabbitMQ.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_RabbitMQ_ha.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_RabbitMQ_ha.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Account.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Account.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Container.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Container.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Object.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Object.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Proxy.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Proxy.xml'
    }
    zabbix_configuration_import { 'Template_App_PuppetDB.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_PuppetDB.xml'
    }
    zabbix_configuration_import { 'Template_App_Puppet_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Puppet_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_Puppet_Master.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Puppet_Master.xml'
    }
    zabbix_configuration_import { 'Template_App_Zabbix_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Zabbix_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_Zabbix_Server.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Zabbix_Server.xml'
    }
    zabbix_configuration_import { 'Template_Fuel_OS_Linux.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_Fuel_OS_Linux.xml'
    }
    zabbix_configuration_import { 'Template_OpenStack_Cluster.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_OpenStack_Cluster.xml'
    }

    ### TEMPLATE IMPORT - END 
    zabbix_template_link { "$::fqdn Template App Zabbix Server":
      host => $::fqdn,
      template => 'Template App Zabbix Server',
      tag => "cluster-${deployment_id}"
    }
    
  }

  #Virtual host for openstack cluster monitoring
  if $::fqdn == $virtualhost_cluster_fqdn {
    package {
      'python-sqlalchemy':
        ensure => present;
      'MySQL-python':
        ensure => present;
      'python-simplejson':
        ensure => present;
    }
    
    zabbix_host { "${virtualhost_cluster_name}":
      host    => $virtualhost_cluster_name,
      ip      => $::internal_address,
      groups  => 'ManagedByPuppet',
      tag => "cluster-${deployment_id}"
    }

    zabbix_template_link { "${virtualhost_cluster_name} Template OpenStack Cluster":
      host    => $virtualhost_cluster_name,
      template => 'Template OpenStack Cluster',
      tag => "cluster-${deployment_id}"
    }

    zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Cinder API check":
      host    => $virtualhost_cluster_name,
      template => 'Template App OpenStack Cinder API check',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Glance API check":
      host    => $virtualhost_cluster_name,
      template => 'Template App OpenStack Glance API check',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Keystone API check":
      host    => $virtualhost_cluster_name,
      template => 'Template App OpenStack Keystone API check',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Nova API OSAPI check":
      host    => $virtualhost_cluster_name,
      template => 'Template App OpenStack Nova API OSAPI check',
      tag => "cluster-${deployment_id}"
    }

    zabbix::agent::userparameter {
      'db.token.count.query':
        command => "/etc/zabbix/scripts/query_db.py token_count";
      'db.instance.error.query':
        command => "/etc/zabbix/scripts/query_db.py instance_error";
      'db.services.offline.nova.query':
        command => "/etc/zabbix/scripts/query_db.py services_offline_nova";
      'db.instance.count.query':
        command => "/etc/zabbix/scripts/query_db.py instance_count";
      'db.cpu.total.query':
        command => "/etc/zabbix/scripts/query_db.py cpu_total";
      'db.cpu.used.query':
        command => "/etc/zabbix/scripts/query_db.py cpu_used";
      'db.ram.total.query':
        command => "/etc/zabbix/scripts/query_db.py ram_total";
      'db.ram.used.query':
        command => "/etc/zabbix/scripts/query_db.py ram_used";
      'db.services.offline.cinder.query':
        command => "/etc/zabbix/scripts/query_db.py services_offline_cinder";
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::zabbix::params::nova_vip} 8774";
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${::zabbix::params::glance_vip} 9292";
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${::zabbix::params::keystone_vip} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${::zabbix::params::keystone_vip} 35357";
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${::zabbix::params::cinder_vip} 8776";
    }
  }
  
  #MySQL server
  if defined(Class['mysql::server']) {

    notice("zabbix debug: found MySQL on $::fqdn, adding template/userparameter")

    zabbix_template_link { "$::fqdn Template App MySQL":
      host => $::fqdn,
      template => 'Template App MySQL',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'mysql.status':
        key     => 'mysql.status[*]',
        command => 'echo "show global status where Variable_name=\'$1\';" | sudo mysql -N | awk \'{print $$2}\'';
      'mysql.size':
        key     => 'mysql.size[*]',
        command =>'echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$1" = "all" || ! "$1" ]] || echo " where table_schema=\'$1\'")$([[ "$2" = "all" || ! "$2" ]] || echo "and table_name=\'$2\'");" | sudo mysql -N';
      'mysql.ping':
        command => 'sudo mysqladmin ping | grep -c alive';
      'mysql.version':
        command => 'mysql -V';
    }

    file { "${::zabbix::params::agent_include_path}/userparameter_mysql.conf":
      ensure => absent,
    }
  }

  #Nova (controller)
  if defined(Class['openstack::controller']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Nova API":
      host => $::fqdn,
      template => 'Template App OpenStack Nova API',
      tag => "cluster-${deployment_id}"
    }
    #zabbix_template_link { "$::fqdn Template App OpenStack Nova API Metadata":
    #  host => $::fqdn,
    #  template => 'Template App OpenStack Nova API Metadata',
    #  tag => "cluster-${deployment_id}"
    #}
    zabbix_template_link { "$::fqdn Template App OpenStack Nova API OSAPI":
      host => $::fqdn,
      template => 'Template App OpenStack Nova API OSAPI',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Nova API OSAPI check":
      host    => $::fqdn,
      template => 'Template App OpenStack Nova API OSAPI check',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Nova API EC2":
      host => $::fqdn,
      template => 'Template App OpenStack Nova API EC2',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Nova Cert":
      host => $::fqdn,
      template => 'Template App OpenStack Nova Cert',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::internal_address} 8774";
    }
  }

  #Nova (compute)
  if defined(Class['openstack::compute']) {
    #zabbix_template_link { "$::fqdn Template App OpenStack Nova API":
    #  host => $::fqdn,
    #  template => 'Template App OpenStack Nova API',
    #  tag => "cluster-${deployment_id}"
    #}
    if ! $::fuel_settings['quantum'] {
      zabbix_template_link { "$::fqdn Template App OpenStack Nova API Metadata":
        host => $::fqdn,
        template => 'Template App OpenStack Nova API Metadata',
        tag => "cluster-${deployment_id}"
      }
    }
  }

  if defined(Class['nova::cert']) {
    # zabbix_template_link { "$::fqdn Template App OpenStack Nova API":
    #   host => $::fqdn,
    #   template => 'Template App OpenStack Nova API'
    # }
  }
  if defined(Class['nova::consoleauth']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Nova ConsoleAuth":
      host => $::fqdn,
      template => 'Template App OpenStack Nova ConsoleAuth',
      tag => "cluster-${deployment_id}"
    }
  }
  if defined(Class['nova::scheduler']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Nova Scheduler":
      host => $::fqdn,
      template => 'Template App OpenStack Nova Scheduler',
      tag => "cluster-${deployment_id}"
    }
  }
  if defined(Class['nova::compute']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Nova Network":
      host => $::fqdn,
      template => 'Template App OpenStack Nova Network',
      tag => "cluster-${deployment_id}"
    }
  } else {
    zabbix_template_link { "$::fqdn Template App OpenStack Nova Network":
      host => $::fqdn,
      template => 'Template App OpenStack Nova Network',
      ensure => absent,
      tag => "cluster-${deployment_id}"
    }
  }
  
  #Cinder
  if defined(Class['cinder::api']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Cinder API":
      host => $::fqdn,
      template => 'Template App OpenStack Cinder API',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Cinder API check":
      host    => $::fqdn,
      template => 'Template App OpenStack Cinder API check',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${::internal_address} 8776";
    }
  }
  if defined(Class['cinder::scheduler']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Cinder Scheduler":
      host => $::fqdn,
      template => 'Template App OpenStack Cinder Scheduler',
      tag => "cluster-${deployment_id}"
    }
  }
  if defined(Class['cinder::volume']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Cinder Volume":
      host => $::fqdn,
      template => 'Template App OpenStack Cinder Volume',
      tag => "cluster-${deployment_id}"
    }
  }

  #Glance
  if defined(Class['glance::api']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Glance API":
      host => $::fqdn,
      template => 'Template App OpenStack Glance API',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Glance API check":
      host    => $::fqdn,
      template => 'Template App OpenStack Glance API check',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${::internal_address} 9292";
    }
  }
  if defined(Class['glance::registry']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Glance Registry":
      host => $::fqdn,
      template => 'Template App OpenStack Glance Registry',
      tag => "cluster-${deployment_id}"
    }
  }

  #Horizon
  if defined(Class['horizon']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Horizon":
      host => $::fqdn,
      template => 'Template App OpenStack Horizon',
      tag => "cluster-${deployment_id}"
    }
  }

  #Swift
  if defined(Class['openstack::swift::storage_node']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Swift Account":
      host => $::fqdn,
      template => 'Template App OpenStack Swift Account',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Swift Container":
      host => $::fqdn,
      template => 'Template App OpenStack Swift Container',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Swift Object":
      host => $::fqdn,
      template => 'Template App OpenStack Swift Object',
      tag => "cluster-${deployment_id}"
    }
  }

  if defined(Class['swift::proxy']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Swift Proxy":
      host => $::fqdn,
      template => 'Template App OpenStack Swift Proxy',
      tag => "cluster-${deployment_id}"
    }
  }

  #Keystone
  if defined(Class['keystone']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Keystone":
      host => $::fqdn,
      template => 'Template App OpenStack Keystone',
      tag => "cluster-${deployment_id}"
    }
    zabbix_template_link { "$::fqdn Template App OpenStack Keystone API check":
      host    => $::fqdn,
      template => 'Template App OpenStack Keystone API check',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${::internal_address} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${::internal_address} 35357";
    }
  }

  #Libvirt
  if defined(Class['nova::compute::libvirt']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Libvirt":
      host => $::fqdn,
      template => 'Template App OpenStack Libvirt',
      tag => "cluster-${deployment_id}"
    }
  }

  #Nova compute
  if defined(Class['nova::compute']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Nova Compute":
      host => $::fqdn,
      template => 'Template App OpenStack Nova Compute',
      tag => "cluster-${deployment_id}"
    }
  }

  #OVS server & db
  if defined(Class['quantum::plugins::ovs']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Open vSwitch":
      host => $::fqdn,
      template => 'Template App OpenStack Open vSwitch',
      tag => "cluster-${deployment_id}"
    }
  }

  #Quantum Open vSwitch Agent
  if defined(Class['quantum::agents::ovs']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Quantum Agent":
      host => $::fqdn,
      template => 'Template App OpenStack Quantum Agent',
      tag => "cluster-${deployment_id}"
    }
  }

  #Quantum server
  if defined(Class['quantum::server']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Quantum Server":
      host => $::fqdn,
      template => 'Template App OpenStack Quantum Server',
      tag => "cluster-${deployment_id}"
    }
  }

  #RabbitMQ server
  if defined(Class['rabbitmq::server']) {
    case $::fuel_settings['deployment_mode'] {
      'multinode': {
        zabbix_template_link { "$::fqdn Template App OpenStack RabbitMQ":
          host => $::fqdn,
          template => 'Template App OpenStack RabbitMQ',
          tag => "cluster-${deployment_id}"
        }
      }
      'ha_compact': {
        zabbix_template_link { "$::fqdn Template App OpenStack HA RabbitMQ":
          host => $::fqdn,
          template => 'Template App OpenStack HA RabbitMQ',
          tag => "cluster-${deployment_id}"
        }
      }
    }
    Class['nova::rabbitmq'] ->
    exec { 'enable rabbitmq management plugin':

      command => 'rabbitmq-plugins enable rabbitmq_management',
      path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      unless  => 'rabbitmq-plugins list -m -E rabbitmq_management | grep -q rabbitmq_management',
      notify  => Exec['restart rabbitmq'],
    }
    exec { 'restart rabbitmq':
      command     => 'service rabbitmq-server restart',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      refreshonly => true,
    }
    firewall {'992 rabbitmq management':
      port   => 55672,
      proto  => 'tcp',
      action => 'accept',
    }
    zabbix::agent::userparameter {
      'rabbitmq.queue.items':
        command => "/etc/zabbix/scripts/check_rabbit.py queues-items";
      'rabbitmq.queues.without.consumers':
        command => "/etc/zabbix/scripts/check_rabbit.py queues-without-consumers";
      'rabbitmq.missing.nodes':
        command => "/etc/zabbix/scripts/check_rabbit.py missing-nodes";
      'rabbitmq.unmirror.queues':
        command => "/etc/zabbix/scripts/check_rabbit.py unmirror-queues";
      'rabbitmq.missing.queues':
        command => "/etc/zabbix/scripts/check_rabbit.py missing-queues";
    }
  }

  if defined(Class['haproxy']) {
    zabbix_template_link { "$::fqdn Template App HAProxy":
      host => $::fqdn,
      template => 'Template App HAProxy',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'haproxy.be.discovery':
        key     => 'haproxy.be.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -b';
      'haproxy.be':
        key     => 'haproxy.be[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
      'haproxy.fe.discovery':
        key     => 'haproxy.fe.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -f';
      'haproxy.fe':
        key     => 'haproxy.fe[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
      'haproxy.sv.discovery':
        key     => 'haproxy.sv.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -s';
      'haproxy.sv':
        key     => 'haproxy.sv[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
    }
    #sudo::directive {'zabbix_socat':
    #  ensure  => present,
    #  content => 'zabbix ALL = NOPASSWD: /usr/bin/socat',
    #}
  }

  if defined(Class['memcached']) {
    zabbix_template_link { "$::fqdn Template App Memcache":
      host => $::fqdn,
      template => 'Template App Memcache',
      tag => "cluster-${deployment_id}"
    }
    zabbix::agent::userparameter {
      'memcache':
        key     => 'memcache[*]',
        command => 'echo -e "stats\nquit" | nc 127.0.0.1 11211 | grep "STAT $1 " | awk \'{print $$3}\''
    }
  }

  #Iptables stats
  if defined(Class['firewall']) {
    zabbix_template_link { "$::fqdn Template App Iptables Stats":
      host => $::fqdn,
      template => 'Template App Iptables Stats',
      tag => "cluster-${deployment_id}"
    }
    package { 'iptstate':
      ensure => present;
    }
    #sudo::directive {'iptstate_users':
    #  ensure  => present,
    #  content => 'zabbix ALL = NOPASSWD: /usr/sbin/iptstate',
    #}
    zabbix::agent::userparameter { 
      'iptstate.tcp':
        command => 'sudo iptstate -1 | grep tcp | wc -l';
      'iptstate.tcp.syn':
        command => 'sudo iptstate -1 | grep SYN | wc -l';
      'iptstate.tcp.timewait':
        command => 'sudo iptstate -1 | grep TIME_WAIT | wc -l';
      'iptstate.tcp.established':
        command => 'sudo iptstate -1 | grep ESTABLISHED | wc -l';
      'iptstate.tcp.close':
        command => 'sudo iptstate -1 | grep CLOSE | wc -l';
      'iptstate.udp':
        command => 'sudo iptstate -1 | grep udp | wc -l';
      'iptstate.icmp':
        command => 'sudo iptstate -1 | grep icmp | wc -l';
      'iptstate.other':
        command => 'sudo iptstate -1 -t | head -2 |tail -1 | sed -e \'s/^.*Other: \(.*\) (.*/\1/\''
    }
  }

}
