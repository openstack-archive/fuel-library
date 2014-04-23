#
#
#

class rsyslog::server (
  $enable_tcp                = true,
  $enable_udp                = true,
  $server_dir                = '/srv/log/',
  $custom_config             = undef,
  $high_precision_timestamps = false,
  $escapenewline             = false,
  $port                      = '514',
) inherits rsyslog {

  File {
    owner => root,
    group => $rsyslog::params::run_group,
    mode => 0640,
    require => Class["rsyslog::config"],
    notify  => Class["rsyslog::service"],
  }

    file { $rsyslog::params::rsyslog_d:
        purge   => true,
        recurse => true,
        force   => true,
        ensure  => directory,
    }

    file { $rsyslog::params::server_conf:
        ensure  => present,
        content => $custom_config ? {
            ''      => template("${module_name}/00-server.conf.erb"),
            default => template($custom_config),
        },
    }
}
