class zabbix::agent inherits zabbix::params {

  firewall { '998 zabbix agent':
    port   => $agent_listen_port,
    proto  => 'tcp',
    action => 'accept',
  }

  package { 'zabbix-agent':
    name   => $agent_pkg,
    ensure => present,
  }

  file { 'agent-include':
    ensure => directory,
    path   => $agent_include,
    mode   => '0500',
    owner  => 'zabbix',
    group  => 'zabbix',
  }

  file { 'agent-config':
    ensure  => present,
    path    => $agent_config,
    content => template($agent_config_template),
  }

  service { 'zabbix-agent':
    name   => $agent_service,
    ensure => running,
    enable => true,
  }

  zabbix_host { $host_name:
    host   => $host_name,
    ip     => $host_ip,
    groups => $host_groups,
    api    => $api_hash,
  }

  Packege['zabbix-agent'] ->
  File['agent-include'] ->
  File['agent-config']

  File['agent-config']    ~> Service['zabbix-agent']
  Package['zabbix-agent'] ~> Service['zabbix-agent']
}
