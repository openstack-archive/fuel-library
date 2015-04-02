class zabbix::server::install inherits zabbix::params {

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

  anchor { 'zabbix_server_db_start': } ->
  class { 'zabbix::server::db': }
  anchor { 'zabbix_server_db_end': }

  service { 'zabbix-server':
    enable    => true,
    name      => $server_service,
    ensure    => running,
  }

  Anchor['zabbix_server_db_end'] ->
  Service['zabbix-server']

  if $frontend {
    anchor { 'zabbix_server_frontend_start': } ->
    class { 'zabbix::server::frontend': }
    anchor { 'zabbix_server_frontend_end': }

    Service['zabbix-server'] ->
    Anchor['zabbix_server_frontend_start']
  }

  firewall { '997 zabbix server':
    proto     => 'tcp',
    action    => 'accept',
    port      => $server_listen_port,
  }

  File['dbconfig-common'] ->
  File['zabbix-server-mysql-conf'] ->
  Package['zabbix-server-package'] ->
  File['zabbix-server-config'] ~>
  Service['zabbix-server']

  Package['zabbix-server-package'] ~>
  Service['zabbix-server']

}
