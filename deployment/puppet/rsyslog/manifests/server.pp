#
#
#

class rsyslog::server (
  $enable_tcp                = true,
  $enable_udp                = true,
  $server_dir                = '/srv/log/',
  $custom_config             = undef,
  $high_precision_timestamps = false,
  $escapenewline             = false
) inherits rsyslog {

include rsyslog::checksum_udp514

  File {
    owner => root,
    group => $rsyslog::params::run_group,
    mode => 0640,
    require => Class["rsyslog::config"],
    notify  => Class["rsyslog::service"],
  }
  
    # TODO test if both client and server classes could be defined for same node
    file { $rsyslog::params::rsyslog_d:  
        purge   => true,    
        recurse => true,    
        force   => true,    
        ensure  => directory,    
    }

    file { "${rsyslog::params::rsyslog_d}30-remote-log.conf":
        content => template("rsyslog/30-remote-log.conf.erb"),

    }

    file { "${rsyslog::params::rsyslog_d}40-puppet-master.conf":
        content => template("rsyslog/40-puppet-master.conf.erb"),

    }
    
    file { $rsyslog::params::server_conf:
        ensure  => present,
        content => $custom_config ? {
            ''      => template("${module_name}/server.conf.erb"),
            default => template($custom_config),
        },
    }
}
