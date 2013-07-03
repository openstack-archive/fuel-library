class rsyslog::config {

  File {
    owner => root,
    group => $rsyslog::params::run_group,
    mode => 0640,
    require => Class["rsyslog::install"],
    notify  => Class["rsyslog::service"],
  }  

    file { $rsyslog::params::rsyslog_conf:
        ensure  => file,
        content => template("${module_name}/rsyslog.conf.erb"),
    }

    file { '/var/lib/rsyslog' :
        ensure  => directory,
        path    => $::rsyslog::params::rsyslog_queues_dir,
    }

case $osfamily {
    'Debian': {
      file { $rsyslog::params::rsyslog_default:
        ensure  => file,
        source  => "puppet:///modules/rsyslog/rsyslog_default",
      }
    }
    'RedHat': {
      file { "/etc/sysconfig/rsyslog":
         content => template("rsyslog/rsyslog.erb"),
      }
    }
    default: {
        fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
}
    file { $rsyslog::params::spool_dir:
        ensure  => directory,
    }
}
