class rsyslog::config {
# assumes rsyslog packages installed at BM or included in distro
  File {
    owner => root,
    group => $rsyslog::params::run_group,
    mode => 0640,
    # To avoid dependency loops for custom runstages
    #require => Class["rsyslog::install"],
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

    file { $rsyslog::params::rsyslog_default:
      ensure  => file,
      content => template("${module_name}/rsyslog_default.erb"),
    }

    file { $rsyslog::params::spool_dir:
        ensure  => directory,
    }
}
