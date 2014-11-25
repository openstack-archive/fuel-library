class zabbix::frontend {

  include zabbix::params

  package { $zabbix::params::frontend_pkg:
    ensure    => present,
    before    => [ File["$zabbix::params::frontend_config"], File["$zabbix::params::frontend_php_ini"] ],
  }

  file { $zabbix::params::frontend_config:
    ensure    => present,
    content   => template($zabbix::params::frontend_config_template),
    notify    => Service[$zabbix::params::frontend_service],
  }

  file { $zabbix::params::frontend_php_ini:
    ensure    => present,
    content   => template($zabbix::params::frontend_php_ini_template),
    notify    => Service[$zabbix::params::frontend_service],
  }
}
