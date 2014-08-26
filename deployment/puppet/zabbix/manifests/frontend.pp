class zabbix::frontend {

  include zabbix::params

  package { $zabbix::params::frontend_pkg:
    ensure    => present,
    before    => [ File["$zabbix::params::frontend_config"], File["$zabbix::params::frontend_php_ini"] ],
  }

  file { $zabbix::params::frontend_config:
    ensure    => present,
    content   => template($zabbix::params::frontend_config_template),
  }

  file { $zabbix::params::frontend_php_ini:
    ensure    => present,
    content   => template($zabbix::params::frontend_php_ini_template),
  }

  service { $zabbix::params::frontend_service:
    ensure    => running,
    require   => Package[$zabbix::params::frontend_pkg],
    subscribe => [ File["$zabbix::params::frontend_config"], File["$zabbix::params::frontend_php_ini"] ],
    enable    => true,
  }
}
