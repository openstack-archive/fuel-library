class zabbix::agent {

  include zabbix::params

  firewall { '998 zabbix agent':
    port   => $zabbix::params::agent_port,
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

  zabbix_host { $zabbix::params::host_name:
    host   => $zabbix::params::host_name,
    ip     => $zabbix::params::host_ip,
    groups => $zabbix::params::host_groups,
    api    => $zabbix::params::api_hash
  }
}
