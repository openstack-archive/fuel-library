class zabbix::db::mysql inherits zabbix::params {

  file { '/tmp/zabbix':
    ensure => directory,
    mode   => '0755',
  }

  file { '/tmp/zabbix/parts':
    ensure  => directory,
    purge   => true,
    force   => true,
    recurse => true,
    mode    => '0755',
    source  => 'puppet:///modules/zabbix/sql',
  }

  file { '/tmp/zabbix/parts/data_clean.sql':
    ensure    => present,
    content   => template('zabbix/data_clean.erb'),
  }

  exec { 'prepare-schema-1':
    command => $prepare_schema_cmd,
    creates => '/tmp/zabbix/schema.sql',
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  }

  exec { 'prepare-schema-2':
    command     => 'cat /tmp/zabbix/parts/*.sql >> /tmp/zabbix/schema.sql',
    path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    refreshonly => true,
  }

  mysql::db { $db_name:
    user          => $db_user,
    password      => $db_password,
    host          => $db_host,
    sql           => '/tmp/zabbix/schema.sql',
  }

  if defined(Class['mysql::server']) {
    Class['mysql::server'] -> Mysql::Db[$db_name]
  }
  Exec['prepare-schema-2'] -> Mysql::Db[$db_name]
  File['/tmp/zabbix/parts/data_clean.sql'] -> Exec['prepare-schema-2']
  Exec['prepare-schema-1'] ~> Exec['prepare-schema-2']
  File['/tmp/zabbix'] -> Exec['prepare-schema-1']
  File['/tmp/zabbix/parts'] -> File['/tmp/zabbix/parts/data_clean.sql']
  File['/tmp/zabbix'] -> File['/tmp/zabbix/parts']
}
