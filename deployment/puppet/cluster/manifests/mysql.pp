# == Class: cluster::mysql
#
# Configure OCF service for mysql managed by corosync/pacemaker
#
# === Parameters
#
# [*primary_controller*]
# [*mysql_user*]
# [*mysql_password*]
# [*mysql_socket*]
#
class cluster::mysql (
  $primary_controller,
  $mysql_user,
  $mysql_password,
  $mysql_config = '/etc/mysql/my.cnf',
  $mysql_socket = '/var/run/mysqld/mysqld.sock',
) {
  $service_name = 'mysqld'

  if $primary_controller {
    cs_resource { "p_${service_name}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'mysql-wss',
      complex_type    => 'clone',
      parameters      => {
        'config'      => $mysql_config,
        'test_user'   => $mysql_user,
        'test_passwd' => $mysql_password,
        'socket'      => $mysql_socket,
      },
      operations      => {
        'monitor' => {
          'interval' => '60',
          'timeout'  => '55'
        },
        'start'   => {
          'timeout' => '300'
        },
        'stop'    => {
          'timeout' => '120'
        },
      },
    }

    Cs_resource["p_${service_name}"] ~>
      Service[$service_name]
    Cs_resource["p_${service_name}"] ->
      Service[$service_name]
  }

  $init_file_contents = join([
    "set wsrep_on='off';",
    "delete from mysql.user where user='';",
    "GRANT USAGE ON *.* TO '${status_user}'@'%' IDENTIFIED BY '${status_password}';",
    "GRANT USAGE ON *.* TO '${status_user}'@'localhost' IDENTIFIED BY '${status_password}';",
    "flush privileges;",
  ], "\n")

  # This file is used to prep the mysql instance with the monitor user so that
  # pacemaker can check that the instance is UP.
  file { 'init-file':
    ensure  => present,
    path    => '/tmp/wsrep-init-file',
    content => $init_file_contents,
    before  => Service[$service_name],
  }

  exec { 'rm-init-file':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'rm /tmp/wsrep-init-file',
  }

  exec { 'wait-for-access':
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    command   => "mysql -u${status_user} -p${status_password} -Nbe \"select 'OK';\" | grep -q OK",
    try_sleep => 10,
    tries     => 60,
  }

  File['init-file'] ->
    Service['mysqld'] ->
      Exec['wait-for-access'] ->
        Exec['rm-init-file']

  #TODO(aschultz): do we need to pull in the waiting for sync?
}
