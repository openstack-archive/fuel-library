class zabbix::frontend inherits zabbix::params {

  package { $frontend_pkg:
    ensure    => present,
  }

  file { $frontend_config:
    ensure    => present,
    content   => template($frontend_config_template),
  }

  file { $frontend_php_ini:
    ensure    => present,
    content   => template($frontend_php_ini_template),
  }

  service { $frontend_service:
    ensure    => running,
    enable    => true,
  }

  Package[$frontend_pkg] -> File[$frontend_config]  ~> Service[$frontend_service]
  Package[$frontend_pkg] -> File[$frontend_php_ini] ~> Service[$frontend_service]
}
