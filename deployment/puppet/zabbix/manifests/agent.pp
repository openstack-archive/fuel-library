class zabbix::agent(
  $api_hash,
) {

  include zabbix::params

  firewall { '997 zabbix agent':
    port   => $zabbix::monitoring::ports['backend_agent'] ? { unset=>$zabbix::monitoring::ports['agent'], default=>$zabbix::monitoring::ports['backend_agent'] },
    proto  => 'tcp',
    action => 'accept'
  }

  package { $zabbix::params::agent_pkg:
    ensure => present
  }
  ->
  file { $zabbix::params::agent_include:
    ensure => directory,
    mode   => '0500',
    owner  => 'zabbix',
    group  => 'zabbix'
  }
  ->
  file { $zabbix::params::agent_config:
    ensure  => present,
    content => template($zabbix::params::agent_config_template),
    notify  => Service[$zabbix::params::agent_service]
  }
  ->
  service { $zabbix::params::agent_service:
    ensure => running,
    enable => true,
  }

  if defined_in_state(Class['openstack::controller']){
    $groups = union($zabbix::params::host_groups_base, $zabbix::params::host_groups_controller)
  } elsif defined_in_state(Class['openstack::compute']) {
    $groups = union($zabbix::params::host_groups_base, $zabbix::params::host_groups_compute)
  } else {
    $groups = $zabbix::params::host_groups_base
  }

  zabbix_host { $zabbix::params::host_name:
    host   => $zabbix::params::host_name,
    ip     => $zabbix::params::host_ip,
    groups => $groups,
    api    => $api_hash
  }
}
