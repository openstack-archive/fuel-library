class zabbix::db::mysql(
  $db_ip,
  $mysql_module  = '0.9',
  $db_password   = 'zabbix',
  $sync_db       = false,
) {

  include zabbix::params

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

  file { '/tmp/zabbix/parts/data_clean.sql':
    ensure    => present,
    require   => File['/tmp/zabbix/parts'],
    content   => template('zabbix/data_clean.erb'),
  }

  exec { 'prepare-schema-1':
    command => $zabbix::params::prepare_schema_cmd,
    creates => '/tmp/zabbix/schema.sql',
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    require => [File['/tmp/zabbix'], Package[$zabbix::params::server_pkg]],
    notify  => Exec['prepare-schema-2'],
  }

  exec { 'prepare-schema-2':
    command     => 'cat /tmp/zabbix/parts/*.sql >> /tmp/zabbix/schema.sql',
    path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    refreshonly => true,
    require     => File['/tmp/zabbix/parts/data_clean.sql'],
  }

  if ($mysql_module >= 2.2) {
    mysql::db { $zabbix::params::db_name:
      user          => $zabbix::params::db_user,
      password      => $db_password,
      host          => $db_ip,
      require       => [Class['mysql::server'], Exec['prepare-schema-2']],
    }
  } else {
    require 'mysql::python'

    mysql::db { $zabbix::params::db_name:
      user         => $zabbix::params::db_user,
      password     => $db_password,
      host         => $db_ip,
      require      => [Class['mysql::config'], Exec['prepare-schema-2']],
    }
  }

  if $sync_db {
    exec{ "$zabbix::params::db_name-import":
      command     => "/usr/bin/mysql $zabbix::params::db_name < /tmp/zabbix/schema.sql",
      logoutput   => true,
      refreshonly => true,
      require     => Database[$zabbix::params::db_name],
      subscribe   => Database[$zabbix::params::db_name],
    }
  }
}
