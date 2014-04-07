class zabbix::monitoring::mysql_mon {

  include zabbix::params

  if defined(Class['mysql::server']) {

    zabbix_template_link { "$zabbix::params::host_name Template App MySQL":
      host => $zabbix::params::host_name,
      template => 'Template App MySQL',
      api => $zabbix::params::api_hash,
    }

    zabbix::agent::userparameter {
      'mysql.status':
        key     => 'mysql.status[*]',
        command => 'echo "show global status where Variable_name=\'$1\';" | sudo mysql -N | awk \'{print $$2}\'';
      'mysql.size':
        key     => 'mysql.size[*]',
        command =>'echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$1" = "all" || ! "$1" ]] || echo " where table_schema=\'$1\'")$([[ "$2" = "all" || ! "$2" ]] || echo "and table_name=\'$2\'");" | sudo mysql -N';
      'mysql.ping':
        command => 'sudo mysqladmin ping | grep -c alive';
      'mysql.version':
        command => 'mysql -V';
    }

    file { "${::zabbix::params::agent_include}/userparameter_mysql.conf":
      ensure => absent,
    }

    if defined(Class['zabbix::db::mysql']) {
      file { "/var/lib/zabbix":
        ensure => directory,
      }

      file { "/var/lib/zabbix/.my.cnf":
        ensure => present,
        content => template('zabbix/.my.cnf.erb'),
      }
    }
  }
}
