#
#
#

class rsyslog::server (
  $enable_tcp                = true,
  $enable_udp                = true,
  $port                      = '514',
  $server_dir                = '/srv/log/',
  $custom_config             = undef,
  $high_precision_timestamps = false,
  $escapenewline             = false,
  $virtual                   = true,
) inherits rsyslog {

# Fix for udp checksums should be applied if running on virtual node
if $virtual { include rsyslog::checksum_udp514 }

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

    file { "${rsyslog::params::rsyslog_d}30-remote-log.conf":
        content => template("${module_name}/30-server-remote-log.conf.erb"),

    }

    file { "${rsyslog::params::rsyslog_d}40-puppet-master.conf":
        content => template("${module_name}/40-server-puppet-master.conf.erb"),

    }

    file { "${rsyslog::params::rsyslog_d}60-puppet-agent.conf":
        content => template("${module_name}/60-puppet-agent.conf.erb"),
    }

    file { $rsyslog::params::server_conf:
        ensure  => present,
        content => $custom_config ? {
            ''      => template("${module_name}/00-server.conf.erb"),
            default => template($custom_config),
        },
    }
}
