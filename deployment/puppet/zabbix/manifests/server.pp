class zabbix::server {

  include zabbix::params

  Anchor<| title == 'zabbix_db_end' |> -> Anchor<| title == 'zabbix_frontend_start' |>

  class { 'zabbix::db': }
  anchor { 'zabbix_db_start': } -> Class['zabbix::db'] -> anchor { 'zabbix_db_end': }

  package { $zabbix::params::server_pkg:
    ensure    => present,
  }

  service { $zabbix::params::server_service:
    enable    => true,
    ensure    => running,
    require   => [Class['zabbix::db'], File[$zabbix::params::server_config]],
  }

  file { $zabbix::params::server_config:
    ensure    => present,
    require   => Package[$zabbix::params::server_pkg],
    content   => template($zabbix::params::server_config_template),
  }

  if $zabbix::params::frontend {
    class { 'zabbix::frontend': }
    anchor { 'zabbix_frontend_start': } -> Class['zabbix::frontend'] -> anchor { 'zabbix_frontend_end': }
  }

  firewall { '999 zabbix agent':
    proto     => 'tcp',
    action    => 'accept',
    port      => $zabbix::params::server_port,
  }

}
