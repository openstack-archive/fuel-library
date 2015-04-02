class zabbix::agent::common inherits zabbix::params {

  file { 'agent-scripts':
    ensure    => directory,
    path      => $agent_scripts,
    recurse   => true,
    purge     => true,
    force     => true,
    mode      => '0755',
    source    => 'puppet:///modules/zabbix/scripts',
  }

  file { '/etc/zabbix/check_api.conf':
    ensure      => present,
    content     => template('zabbix/check_api.conf.erb'),
  }

  file { '/etc/zabbix/check_rabbit.conf':
    ensure      => present,
    content     => template('zabbix/check_rabbit.conf.erb'),
  }

  file { '/etc/zabbix/check_db.conf':
    ensure      => present,
    content     => template('zabbix/check_db.conf.erb'),
  }

  file { '/etc/sudoers.d':
    ensure => directory,
  }

  file { 'zabbix_no_requiretty':
    path   => '/etc/sudoers.d/zabbix',
    mode   => '0440',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/zabbix/zabbix-sudo',
  }

  if ! defined(Package['sudo']) {
    package { 'sudo':
      ensure => installed,
    }
  }

  file { 'agent-include':
    ensure => directory,
    path   => $agent_include,
    mode   => '0500',
    owner  => 'zabbix',
    group  => 'zabbix',
  }

  zabbix_host { $host_name:
    host   => $host_name,
    ip     => $host_ip,
    groups => $host_groups,
    api    => $api_hash,
  }

  zabbix_usermacro { "${host_name} IP_PUBLIC":
    host  => $host_name,
    macro => '{$IP_PUBLIC}',
    value => $public_address,
    api   => $api_hash,
  }

  zabbix_usermacro { "${host_name} IP_MANAGEMENT":
    host  => $host_name,
    macro => '{$IP_MANAGEMENT}',
    value => $internal_address,
    api   => $api_hash,
  }

  zabbix_usermacro { "${host_name} IP_STORAGE":
    host  => $host_name,
    macro => '{$IP_STORAGE}',
    value => $storage_address,
    api   => $api_hash,
  }

  File['agent-scripts'] -> Zabbix::Agent::Userparameter <||>
  File['agent-include'] -> Zabbix::Agent::Userparameter <||>
}
