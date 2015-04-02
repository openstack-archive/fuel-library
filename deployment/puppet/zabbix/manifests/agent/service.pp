class zabbix::agent::service inherits zabbix::params {

  firewall { '998 zabbix agent':
    port   => $agent_listen_port,
    proto  => 'tcp',
    action => 'accept',
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

  Package['zabbix-agent'] ->
  File['agent-config'] ~>
  Service['zabbix-agent']

  Package['zabbix-agent'] ~>
  Service['zabbix-agent']
}
