class zabbix::server inherits zabbix::params {

  file { 'dbconfig-common':
    ensure    => directory,
    path      => '/etc/dbconfig-common',
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
  }

  file { 'zabbix-server-mysql-conf':
    ensure    => present,
    path      => '/etc/dbconfig-common/zabbix-server-mysql.conf',
    mode      => '0600',
    source    => 'puppet:///modules/zabbix/zabbix-server-mysql.conf',
  }

  package { 'zabbix-server-package':
    ensure    => present,
    name      => $server_pkg,
  }

  file { 'zabbix-server-config':
    ensure    => present,
    path      => $server_config,
    content   => template($server_config_template),
  }

  class { 'zabbix::db': }

  anchor { 'zabbix_db_start': } ->
  File['zabbix-server-config'] ->
  Class['zabbix::db'] ->
  Service['zabbix-server'] ->
  anchor { 'zabbix_db_end': }

  service { 'zabbix-server':
    enable    => true,
    name      => $server_service,
    ensure    => running,
  }

  Anchor<| title == 'zabbix_db_end' |> -> Anchor<| title == 'zabbix_frontend_start' |>

  if $frontend {
    class { 'zabbix::frontend': }

    Service['zabbix-server'] -> Class['zabbix::frontend']

    anchor { 'zabbix_frontend_start': } ->
    Class['zabbix::frontend'] ->
    anchor { 'zabbix_frontend_end': }
  }

  firewall { '997 zabbix server':
    proto     => 'tcp',
    action    => 'accept',
    port      => $server_listen_port,
  }

  File['dbconfig-common'] ->
  File['zabbix-server-mysql-conf'] ->
  Package['zabbix-server-package'] ->
  File['zabbix-server-config']

  File['zabbix-server-config'] ~> Service['zabbix-server']
  Package['zabbix-server-package'] ~> Service['zabbix-server']

}
