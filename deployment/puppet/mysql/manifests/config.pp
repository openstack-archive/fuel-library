# Class: mysql::config
#
# Parameters:
#
#   [*root_password*]     - root user password.
#   [*old_root_password*] - previous root user password,
#   [*bind_address*]      - address to bind service.
#   [*port*]              - port to bind service.
#   [*etc_root_password*] - whether to save /etc/.my.cnf.
#   [*service_name*]      - mysql service name.
#   [*config_file*]       - my.cnf configuration file path.
#   [*socket*]            - mysql socket.
#   [*datadir*]           - path to datadir.
#   [*ssl]                - enable ssl
#   [*ssl_ca]             - path to ssl-ca
#   [*ssl_cert]           - path to ssl-cert
#   [*ssl_key]            - path to ssl-key
#
# Actions:
#
# Requires:
#
#   class mysql::server
#
# Usage:
#
#   class { 'mysql::config':
#     root_password => 'changeme',
#     bind_address  => $::ipaddress,
#   }
#
class mysql::config(
  $bind_address      = $mysql::params::bind_address,
  $port              = $mysql::params::port,
  $service_name      = $mysql::params::service_name,
  $config_file       = $mysql::params::config_file,
  $socket            = $mysql::params::socket,
  $pidfile           = $mysql::params::pidfile,
  $datadir           = $mysql::params::datadir,
  $ssl               = $mysql::params::ssl,
  $ssl_ca            = $mysql::params::ssl_ca,
  $ssl_cert          = $mysql::params::ssl_cert,
  $ssl_key           = $mysql::params::ssl_key,
  $log_error         = $mysql::params::log_error,
  $default_engine    = 'UNSET',
  $root_group        = $mysql::params::root_group,
  $use_syslog        = false,
  $custom_setup_class = undef,
  $server_id         = $mysql::params::server_id,
) inherits mysql::params {

  $mysql_buffer_pool_size = $::mysql::params::mysql_buffer_pool_size
  $mysql_log_file_size    = $::mysql::params::mysql_log_file_size
  $max_connections = $::mysql::params::max_connections
  $table_open_cache = $::mysql::params::table_open_cache
  $key_buffer_size = $::mysql::params::key_buffer_size
  $myisam_sort_buffer_size = $::mysql::params::myisam_sort_buffer_size
  $wait_timeout = $::mysql::params::wait_timeout
  $open_files_limit= $::mysql::params::open_files_limit

  if $custom_setup_class != "pacemaker_mysql" {
    File {
      owner  => 'root',
      group  => $root_group,
      mode   => '0400',
      notify => Exec['mysqld-restart'],
    }
  } else {
    File {
      owner  => 'root',
      group  => $root_group,
      mode   => '0400',
      notify => Service['mysql'],
    }
  }

  if ($custom_setup_class == undef) {

    if $ssl and $ssl_ca == undef {
      fail('The ssl_ca parameter is required when ssl is true')
    }

    if $ssl and $ssl_cert == undef {
      fail('The ssl_cert parameter is required when ssl is true')
    }

    if $ssl and $ssl_key == undef {
      fail('The ssl_key parameter is required when ssl is true')
    }

    # This kind of sucks, that I have to specify a difference resource for
    # restart.  the reason is that I need the service to be started before mods
    # to the config file which can cause a refresh
    exec { 'mysqld-restart':
      command     => "service ${service_name} restart",
      logoutput   => on_failure,
      refreshonly => true,
      path        => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
    }

    file { '/etc/mysql':
      ensure => directory,
      mode   => '0755',
    }
    file { '/etc/mysql/conf.d':
      ensure => directory,
      mode   => '0755',
    }

    #FIXME(bogdando): dirtyhack to pervert imperative puppet nature.
    if $::mysql_log_file_size_real != $mysql_log_file_size {
      # delete MySQL ib_logfiles, if log file size does not match the one
      # from params
      exec { 'delete_logfiles':
        command     => "rm -f ${datadir}/ib_logfile* || true",
        path        => [ '/sbin/', '/usr/sbin/', '/usr/bin/' ,'/bin/' ],
        before      => File[$config_file],
      }
      # use predefined value for log file size
      $innodb_log_file_size_real = $mysql_log_file_size
    } else {
      # evaluate existing log file size and use it as a value
      $innodb_log_file_size_real = $::mysql_log_file_size_real
    }

    file { $config_file:
      content => template('mysql/my.cnf.erb'),
      mode    => '0644',
    }
  }
}
