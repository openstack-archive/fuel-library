# == Class: cluster::mysql
#
# Configure OCF service for mysql managed by corosync/pacemaker
#
# === Parameters
#
# [*primary_controller*]
#  (required). Boolean. Flag to indicate if this on the primary contoller
#
# [*mysql_user*]
#  (required). String. Mysql user to use for connection testing and status
#  checks.
#
# [*mysql_password*]
#  (requires). String. Password for the mysql user to checks with.
#
# [*mysql_config*]
#  (optional). String. Location to the mysql.cnf to use when running the
#  service.
#  Defaults to '/etc/mysql/my.cnf'
#
# [*mysql_socket*]
#  (optional). String. The socket file to use for connection checks.
#  Defaults to '/var/run/mysqld/mysqld.sock'
#
class cluster::mysql (
  $mysql_user,
  $mysql_password,
  $mysql_config = '/etc/mysql/my.cnf',
  $mysql_socket = '/var/run/mysqld/mysqld.sock',
) {
  $service_name       = 'mysqld'
  $primitive_class    = 'ocf'
  $primitive_provider = 'fuel'
  $primitive_type     = 'mysql-wss'
  $complex_type       = 'clone'

  $user_conf = '/etc/mysql/user.cnf'
  file { $user_conf:
    owner   => 'root',
    mode    => '0600',
    content => template('cluster/mysql_user.cnf.erb')
  } -> Exec <||>

  $parameters = {
    'config'      => $mysql_config,
    'test_conf'   => $user_conf,
    'socket'      => $mysql_socket,
  }

  $operations = {
    'monitor' => {
      'interval' => '60',
      'timeout'  => '55'
    },
    'start'   => {
      'interval' => '30',
      'timeout'  => '330',
      'on-fail'  => 'restart',
    },
    'stop'    => {
      'interval' => '0',
      'timeout'  => '120'
    },
  }

  $metadata        = {
    'migration-threshold' => '10',
    'failure-timeout'     => '30s',
    'resource-stickiness' => '100',
  }

  $complex_metadata     = {
    'requires'      => 'nothing',
  }

  pacemaker::service { $service_name:
    primitive_class    => $primitive_class,
    primitive_provider => $primitive_provider,
    primitive_type     => $primitive_type,
    complex_type       => $complex_type,
    complex_metadata   => $complex_metadata,
    metadata           => $metadata,
    parameters         => $parameters,
    operations         => $operations,
    prefix             => true,
  }

  # NOTE(aschultz): strings must contain single quotes only, see the
  # create-init-file exec as to why
  $init_file_contents = join([
    "set wsrep_on='off';",
    "delete from mysql.user where user='';",
    "GRANT USAGE ON *.* TO '${mysql_user}'@'%' IDENTIFIED BY '${mysql_password}';",
    "GRANT USAGE ON *.* TO '${mysql_user}'@'localhost' IDENTIFIED BY '${mysql_password}';",
    "flush privileges;",
  ], "\n")

  # NOTE(bogdando) it's a positional param, must go first
  $user_password_string = "--defaults-extra-file=${user_conf}"

  # This file is used to prep the mysql instance with the monitor user so that
  # pacemaker can check that the instance is UP.
  # NOTE(aschultz): we are using an exec here because we only want to create
  # the init file before the mysql service is not running. This is used to
  # bootstrap the service so we only do it the first time. For idempotency
  # this exec would be skipped when run a second time with mysql running.
  exec { 'create-init-file':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "echo \"${init_file_contents}\" > /tmp/wsrep-init-file",
    unless  => "mysql ${user_password_string} -Nbe \"select 'OK';\" | grep -q OK",
    require => Package['mysql-server'],
  } ~>

  exec { 'wait-for-sync':
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
    command     => "mysql ${user_password_string} -Nbe \"show status like 'wsrep_local_state_comment'\" | grep -q -e Synced && sleep 10",
    try_sleep   => 10,
    tries       => 60,
    refreshonly => true,
  }

  exec { 'rm-init-file':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'rm /tmp/wsrep-init-file',
    onlyif  => 'test -f /tmp/wsrep-init-file',
  }

  file { 'fix-log-dir':
    ensure  => directory,
    path    => '/var/log/mysql',
    mode    => '0770',
    require => Package['mysql-server'],
  }

  Exec['create-init-file'] ->
    File['fix-log-dir'] ->
      Service<| title == $service_name |> ~>
        Exec['wait-for-sync'] ->
          Exec['rm-init-file']
}
