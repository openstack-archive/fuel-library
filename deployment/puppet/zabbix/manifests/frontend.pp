# == Class: zabbix::frontend
#
# Install and manage zabbix frontend
#
class zabbix::frontend {

  include zabbix::params

  validate_string($zabbix::params::server_hostname)
  validate_string($zabbix::params::server_name)
  validate_string($zabbix::params::frontend_hostname)

  package { $zabbix::params::frontend_package:
    ensure => $ensure,
  }

  service { $zabbix::params::http_service:
    ensure  => running,
    require => Package[$zabbix::params::frontend_package],
  }

  file { $zabbix::params::frontend_conf_file:
    ensure  => present,
    content => template('zabbix/zabbix.conf.php.erb'),
    require => Package[$zabbix::params::frontend_package]
  }

  file { $zabbix::params::php_ini_file:
    ensure  => present,
    content => template('zabbix/php_ini.erb'),
    notify  => Service[$zabbix::params::http_service],
    require => Package[$zabbix::params::frontend_package]
  }
  
  

}
