
define mmm::agent::config($localsubnet, $replication_user,
  $replication_password, $agent_user, $agent_password, $monitor_user,
  $monitor_password, $reader_user, $reader_pass, $writer_user, $writer_pass,
  $writer_virtual_ip, $reader_virtual_ips, $server_id, $num_servers, $peer) {

  include mmm::params

  database_user{ $replication_user:
    name          => "${replication_user}@${localsubnet}",
    password_hash => mysql_password($replication_password),
  }
  database_grant{ "${replication_user}@${localsubnet}":
    privileges => ['repl_slave_priv']
  }


  database_user{ $agent_user:
    name          => "${agent_user}@${localsubnet}",
    password_hash => mysql_password($agent_password),
  }
  database_grant{ "${agent_user}@${localsubnet}":
    privileges => ['repl_client_priv', 'super_priv', 'process_priv']
  }

  database_user{ $monitor_user:
    name          => "${monitor_user}@${localsubnet}",
    password_hash => mysql_password($monitor_password),
  }
  database_grant{ "${monitor_user}@${localsubnet}":
    privileges => ['repl_client_priv']
  }

  # only create reader user if it is specified, on clusters without readers it won't be necessary
  if ($reader_user != '') {
    database_user{ $reader_user:
      name          => "${reader_user}@${localsubnet}",
      password_hash => mysql_password($reader_pass),
    }
    database_grant{ "${reader_user}@${localsubnet}":
      privileges => ['select_priv']
    }
  }

  database_user{ $writer_user:
    name          => "${writer_user}@${localsubnet}",
    password_hash => mysql_password($writer_pass),
  }
  database_grant{ "${writer_user}@${localsubnet}":
    privileges => ['select_priv', 'update_priv', 'insert_priv', 'delete_priv', 'create_priv', 'alter_priv', 'drop_priv']
  }

  file { '/etc/mysql-mmm/mmm_agent.conf':
    ensure  => present,
    mode    => 0600,
    owner   => 'root',
    group   => 'root',
    content => template('mmm/mmm_agent.conf.erb'),
    require => Package['mysql-mmm-agent'],
  }

  file { '/etc/init.d/mysql-mmm-agent':
    ensure  => present,
    mode    => 0755,
    owner   => 'root',
    group   => 'root',
    content => template('mmm/agent-init-d.erb'),
    require => Package['mysql-mmm-agent'],
  }

  service { 'mysql-mmm-agent':
    ensure         => running,
    subscribe      => [
      Package[mysql-mmm-agent],
      File['/etc/mysql-mmm/mmm_agent.conf'],
      File['/etc/mysql-mmm/mmm_common.conf']
    ],
    enable         => true,
    hasrestart     => true,
    hasstatus      => true,
    require        => [
      Package[mysql-mmm-agent],
      File['/etc/mysql-mmm/mmm_agent.conf'],
      File['/etc/mysql-mmm/mmm_common.conf']
    ]
  }

  augeas { "my.cnf/replication":
    context => "/files/etc/mysql/my.cnf/target[3]/",
    load_path => "/usr/share/augeas/lenses/dist",
    changes => [
        "set bind-address 0.0.0.0",
		"set server_id ${server_id}",
		"set log-bin /var/log/mysql/mysql-bin.log",
		"set log_bin_index /var/log/mysql/mysql-bin.log.index",
		"set relay_log /var/log/mysql/mysql-relay-bin",
		"set relay_log_index /var/log/mysql/mysql-relay-bin.index",
		"set expire_logs_days 10",
		"set max_binlog_size 100M",
        "set auto_increment_increment ${num_servers}",
        "set auto_increment_offset ${server_id}",
        "set binlog-ignore-db mysql",
        "set skip-name-resolve ''"
    ],
    require => File["/etc/mysql/my.cnf"],
    notify => Exec['mysqld-restart']
  }

  Exec['mysqld-restart'] ->
  exec {"get_master":
    command => "/usr/bin/mysql -h ${peer} -u ${agent_user} -p${agent_password} -NBe 'show master status' |awk '{printf \"CHANGE MASTER TO master_host=\\\"${peer}\\\", master_port=3306, master_user=\\\"replication\\\", master_password=\\\"${replication_password}\\\", master_log_file=\\\"%s\\\", master_log_pos=%s\",\$1,\$2}'> /etc/mysql/master_info",
    unless => "/usr/bin/mysql -h ${peer} -u ${replication_user} -p${replication_password} -NBe \"SELECT 1\" && [ -e /etc/mysql/replication.done ]"
  }->
  exec {"slave_stop":
    command => "/usr/bin/mysql -u root -NBe \"SLAVE STOP\"",
    unless => "/usr/bin/test -e /etc/mysql/master_info && [ -e /etc/mysql/replication.done ]",
  }->
  exec {"change master_to":
    command => "/usr/bin/mysql -u root < /etc/mysql/master_info",
    unless => "/usr/bin/test -e /etc/mysql/master_info && [ -e /etc/mysql/replication.done ]",
  }->
  exec {"slave_start":
    command => "/usr/bin/mysql -u root -NBe \"SLAVE START\"",
    unless => "/usr/bin/test -e /etc/mysql/master_info && [ -e /etc/mysql/replication.done ]",
  }->
  exec { "test_greplication":
    command => "/usr/bin/touch /etc/mysql/replication.done",
    unless => "/usr/bin/mysql -NBe 'SHOW SLAVE STATUS\\G'|grep 'Waiting for master to send event'"
  }->
  file { '/etc/mysql/replication.done':
    ensure => present,
  }
}
