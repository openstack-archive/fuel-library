class zabbix::frontend {

  include zabbix::params

  package { $zabbix::params::frontend_pkg:
    ensure    => present,
  }

  file { $zabbix::params::frontend_config:
    ensure    => present,
    require   => Package[$zabbix::params::frontend_pkg],
    content   => template($zabbix::params::frontend_config_template),
  }

  file { $zabbix::params::frontend_php_ini:
    ensure    => present,
    require   => Package[$zabbix::params::frontend_pkg],
    content   => template($zabbix::params::frontend_php_ini_template),
    notify    => Service[$zabbix::params::frontend_service]
  }

  service { $zabbix::params::frontend_service:
    ensure   => running,
    require  => Package[$zabbix::params::frontend_pkg],
    enable   => true,
  }
}
