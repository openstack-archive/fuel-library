class zabbix::db::mysql {

  include zabbix::params

  class { 'mysql::server':
    config_hash => {
      'root_password' => $zabbix::params::db_root_password,
      'bind_address'  => '0.0.0.0',
    },
    enabled    => true,
  }
  anchor { 'mysql_server_start': } -> Class['mysql::server'] -> anchor { 'mysql_server_end': }

  file { '/tmp/zabbix':
    ensure => directory,
    mode   => 0755,
  } 

  file { '/tmp/zabbix/parts':
    ensure  => directory,
    purge   => true,
    force   => true,
    recurse => true,
    mode    => '0755',
    source  => 'puppet:///modules/zabbix/sql',
    require => File['/tmp/zabbix']
  }

  exec { 'prepare-schema-1': 
    command => $zabbix::params::prepare_schema_cmd,
    creates => '/tmp/zabbix/schema.sql',
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    require => File['/tmp/zabbix'],
    notify  => Exec['prepare-schema-2']
  }

  exec { 'prepare-schema-2':
    command     => 'cat /tmp/zabbix/parts/*.sql >> /tmp/zabbix/schema.sql',
    path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    refreshonly => true,
    require     => File['/tmp/zabbix/parts']
  }

  mysql::db { $zabbix::params::db_name:
    user          => $zabbix::params::db_user,
    password      => $zabbix::params::db_password,
    host          => $zabbix::params::db_host,
    sql           => '/tmp/zabbix/schema.sql',
    require       => [Class['mysql::server'], Exec['prepare-schema-2']],
  }
}
