class zabbix::server {

  include zabbix::params

  file { '/etc/dbconfig-common':
    ensure    => directory,
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
  }

  file { '/etc/dbconfig-common/zabbix-server-mysql.conf':
    require   => File['/etc/dbconfig-common'],
    ensure    => present,
    mode      => '0600',
    source    => 'puppet:///modules/zabbix/zabbix-server-mysql.conf',
  }

  package { $zabbix::params::server_pkg:
    require   => File['/etc/dbconfig-common/zabbix-server-mysql.conf'],
    ensure    => present,
  }

  file { $zabbix::params::server_config:
    ensure    => present,
    require   => Package[$zabbix::params::server_pkg],
    content   => template($zabbix::params::server_config_template),
  }

  class { 'zabbix::db': }
  anchor { 'zabbix_db_start': } -> File[$zabbix::params::server_config] -> Class['zabbix::db'] -> Service[$zabbix::params::server_service] -> anchor { 'zabbix_db_end': }

  service { $zabbix::params::server_service:
    enable    => true,
    ensure    => running,
    require   => File[$zabbix::params::server_config],
  }

  Anchor<| title == 'zabbix_db_end' |> -> Anchor<| title == 'zabbix_frontend_start' |>

  if $zabbix::params::frontend {
    class { 'zabbix::frontend': 
      require => Service[$zabbix::params::server_service],
    }
    anchor { 'zabbix_frontend_start': } -> Class['zabbix::frontend'] -> anchor { 'zabbix_frontend_end': }
  }

  firewall { '997 zabbix server':
    proto     => 'tcp',
    action    => 'accept',
    port      => $zabbix::params::server_listen_port,
  }

}
