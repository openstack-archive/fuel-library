  # == Class: zabbix::server
#
# Set up a Zabbix server
#
# === Parameters
#
# [*ensure*]
#  present or absent
# [*hostname*]
#  hostname of local machine
# [*export*]
#  present or absent, use storeconfigs to inform clients of server location
# [*conf_file*]
#  path to configuration file
# [*template*]
#  name of puppet template used
# [*node_id*]
# [*db_server*]
#  mysql server hostname
# [*db_database*]
#  mysql server schema name
# [*db_user*]
#  mysql server username
# [*db_password*]
#  mysql server password
#
class zabbix::server {

  include zabbix::params

  firewall {'991 zabbix agent':
    port   => $zabbix::params::server_listen_port,
    proto  => 'tcp',
    action => 'accept',
  }

  #@@zabbix::serverconfig { $fqdn:
  #  ip  => $::management_address,
  #  tag => "cluster-${deployment_id}"
  #}

  class { "mysql::server":
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # TODO I should make sure that this works
      # 'root_password' => $mysql_root_password,
      'root_password' => $zabbix::params::db_root_password,
      'bind_address'  => '0.0.0.0'
    },
    enabled => true,
  }

  package { $zabbix::params::server_package:
    ensure      => latest,
  }

  file { $zabbix::params::server_conf_file:
    ensure      => present,
    content     => template($zabbix::params::server_template),
    notify      => Service[$zabbix::params::server_service_name],
    require     => Package[$zabbix::params::server_package]
  }

  service { $zabbix::params::server_service_name:
    ensure      => running,
    enable      => true,
    require     => [ File[$zabbix::params::server_conf_file], Mysql::Db[$zabbix::params::db_name] ]
  }

  file { '/tmp/zabbix-schema-tmp':
    ensure => directory,
    mode => '0755',
  }

  file { '/tmp/zabbix-schema-tmp/local':
    ensure    => directory,
    recurse   => true,
    purge     => true,
    force     => true,
    mode      => '0755',
    source    => 'puppet:///modules/zabbix/sql',
    require   => File['/tmp/zabbix-schema-tmp']
  }

  exec { 'prepare-schema-import':
    command       => $zabbix::params::prepare_schema_command,
    creates       => '/tmp/zabbix-schema-tmp/all.sql',
    require       => [Package[$zabbix::params::server_package], File['/tmp/zabbix-schema-tmp']],
    path          => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
    notify        => Exec['prepare-schema-import-late']
  }

  exec { 'prepare-schema-import-late':
    command       => 'cat /tmp/zabbix-schema-tmp/local/*.sql >> /tmp/zabbix-schema-tmp/all.sql',
    require       => File['/tmp/zabbix-schema-tmp/local'],
    refreshonly   => true,
    path          => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
  }

  mysql::db { $zabbix::params::db_name:
    user          => $zabbix::params::db_user,
    password      => $zabbix::params::db_password,
    host          => $zabbix::params::db_host,
    sql           => '/tmp/zabbix-schema-tmp/all.sql',
    require       => [Class['mysql::server'], Class['mysql::config'], Package[$zabbix::params::server_package], Exec['prepare-schema-import'], Exec['prepare-schema-import-late']],
  }


  if ($zabbix::params::frontend_ensure == present) {
    include zabbix::frontend
    Mysql::Db[$zabbix::params::db_name] -> Class['zabbix::frontend']
  }

  if ($zabbix::params::api_ensure == present) {
    include zabbix::api
    Class['zabbix::frontend'] -> Class['zabbix::api']
  }

  if ($zabbix::params::reports_ensure == present) {
    include zabbix::reports
  }

  zabbix_hostgroup { 'ManagedByPuppet': }

  if ($zabbix::params::export_ensure == present and $zabbix::params::api_ensure == present) {

    zabbix_host { 'Zabbix server':
      ensure => absent
    }
  }
  Zabbix_usermacro { require => Class['zabbix::api'] }
  Zabbix_template_link { require => Class['zabbix::api'] }
  Zabbix_host { require => [Class['zabbix::api'], Zabbix_hostgroup['ManagedByPuppet']] }
  Zabbix_hostgroup { require => Class['zabbix::api'] }
}
