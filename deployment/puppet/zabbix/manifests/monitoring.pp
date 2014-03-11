class zabbix::monitoring {

  include zabbix::params

  zabbix_usermacro { "$zabbix::params::host_name IP_PUBLIC":
    host  => $zabbix::params::host_name,
    macro => '{$IP_PUBLIC}',
    value => $::public_address,
    api   => $zabbix::params::api_hash,
  }

  zabbix_usermacro { "$zabbix::params::host_name IP_MANAGEMENT":
    host  => $zabbix::params::host_name,
    macro => '{$IP_MANAGEMENT}',
    value => $::internal_address,
    api   => $zabbix::params::api_hash,
  }

  zabbix_usermacro { "$zabbix::params::host_name IP_STORAGE":
    host  => $zabbix::params::host_name,
    macro => '{$IP_STORAGE}',
    value => $::storage_address,
    api   => $zabbix::params::api_hash,
  }
  #Zabbix::agent::userparameter { require => Class['zabbix::agent::scripts'] }

  Anchor<| title == 'zabbix_agent_end' |> -> Anchor<| title == 'zabbix_agent_scripts_begin' |>

  class { 'zabbix::agent': }
  anchor { 'zabbix_agent_begin': } -> Class['zabbix::agent'] -> anchor { 'zabbix_agent_end': }

  class { 'zabbix::agent::scripts': }
  anchor { 'zabbix_agent_scripts_begin': } -> Class['zabbix::agent::scripts'] -> anchor { 'zabbix_agent_scripts_end': }

  zabbix::agent::userparameter {
    'vfs.dev.discovery':
      ensure => 'present',
      command => '/etc/zabbix/scripts/vfs.dev.discovery.sh';
    'vfs.mdadm.discovery':
      ensure => 'present',
      command => '/etc/zabbix/scripts/vfs.mdadm.discovery.sh';
    'proc.vmstat':
      key => 'proc.vmstat[*]',
      command => 'grep \'$1\' /proc/vmstat | awk \'{print $$2}\'';
    'crm.node.check':
      key     => 'crm.node.check[*]',
      command => '/etc/zabbix/scripts/crm_node_check.sh $1';
  }

  #Linux
  zabbix_template_link { "$zabbix::params::host_name Template Fuel OS Linux":
    host => $zabbix::params::host_name,
    template => 'Template Fuel OS Linux',
    api => $zabbix::params::api_hash,
  }

  #Zabbix Agent
  zabbix_template_link { "$zabbix::params::host_name Template App Zabbix Agent":
    host => $zabbix::params::host_name,
    template => 'Template App Zabbix Agent',
    api => $zabbix::params::api_hash,
  }

  Zabbix_usermacro { require => Class['zabbix::agent'] }
  Zabbix_template_link { require => Class['zabbix::agent'] }

  # Auto-registration
  include zabbix::monitoring::nova_mon
  include zabbix::monitoring::keystone_mon
  include zabbix::monitoring::glance_mon
  include zabbix::monitoring::cinder_mon
  include zabbix::monitoring::swift_mon
  include zabbix::monitoring::rabbitmq_mon
  include zabbix::monitoring::horizon_mon
  include zabbix::monitoring::mysql_mon
  include zabbix::monitoring::memcached_mon
  include zabbix::monitoring::haproxy_mon
  include zabbix::monitoring::zabbixserver_mon
  include zabbix::monitoring::openstack_virtual_mon
  include zabbix::monitoring::firewall_mon
  include zabbix::monitoring::neutron_mon
  include zabbix::monitoring::openvswitch_mon
  include zabbix::monitoring::ceilometer_mon
  include zabbix::monitoring::ceilometer_compute_mon
}
