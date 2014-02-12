# == Class: zabbix::agent
#
# Install and manage a zabbix agent. Have a look at zabbix::agent::userparameter if you
# need to use custom UserParameters.
#
class zabbix::agent {

  include zabbix::params

  validate_absolute_path($zabbix::params::agent_conf_file)
  validate_absolute_path($zabbix::params::agent_pid_file)
  validate_hash($zabbix::params::userparameters)

  firewall {'990 zabbix agent':
    port   => $zabbix::params::agent_listen_port,
    proto  => 'tcp',
    action => 'accept',
  }

  package { $zabbix::params::agent_package:
    ensure    => latest,
  }

  file { $zabbix::params::agent_include_path:
    ensure    => directory,
    mode      => '0500',
    owner     => 'zabbix',
    group     => 'zabbix',
    require   => Package[$zabbix::params::agent_package]
  }

  #Zabbix::Serverconfig <<| tag == "cluster-${deployment_id}" |>> {
  #  notify    => Service[$zabbix::params::agent_service_name],
  #  require   => File[$zabbix::params::agent_include_path]
  #}

  file { $zabbix::params::agent_conf_file:
    ensure    => present,
    content   => template($zabbix::params::agent_template),
    notify    => Service[$zabbix::params::agent_service_name],
    require   => Package[$zabbix::params::agent_package]
  }

  service { $zabbix::params::agent_service_name:
    ensure    => running,
    enable    => true,
    require   => File[$zabbix::params::agent_conf_file]
  }

  if ($zabbix::params::api_ensure == present) {
    include zabbix::api
    if !defined(Zabbix_hostgroup['ManagedByPuppet']) {
      zabbix_hostgroup { 'ManagedByPuppet': }
    }
    zabbix_host { $::fqdn:
      host    => $::fqdn,
      ip      => $::internal_address,
      groups  => 'ManagedByPuppet',
      tag     => "cluster-${deployment_id}",
      require => Zabbix_hostgroup['ManagedByPuppet']
    }
  }

}
