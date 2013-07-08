class mysql::server::monitor (
  $mysql_monitor_username,
  $mysql_monitor_password,
  $mysql_monitor_hostname,
  $host = false,
  $port = false,
  $authorized_user = false,
  $authorized_pass = false,
) {

  Class['mysql::server'] -> Class['mysql::server::monitor']

  database_user{ "${mysql_monitor_username}@${mysql_monitor_hostname}":
    host            => $host,
    port            => $port,
    authorized_user => $authorized_user,
    authorized_pass => $authorized_pass,
    password_hash => mysql_password($mysql_monitor_password),
    ensure        => present,
  }

  database_grant { "${mysql_monitor_username}@${mysql_monitor_hostname}":
    host            => $host,
    port            => $port,
    authorized_user => $authorized_user,
    authorized_pass => $authorized_pass,
    privileges => [ 'process_priv', 'super_priv' ],
    require    => Mysql_user["${mysql_monitor_username}@${mysql_monitor_hostname}"],
  }

}
