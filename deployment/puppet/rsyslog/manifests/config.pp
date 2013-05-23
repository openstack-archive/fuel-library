class rsyslog::config {
    file { $rsyslog::params::rsyslog_d:
        owner   => root,
        group   => $rsyslog::params::run_group,
        purge   => true,
        recurse => true,
        force   => true,
        require => Class["rsyslog::install"],
        ensure  => directory,
    }

    file { $rsyslog::params::rsyslog_conf:
        owner   => root,
        group   => $rsyslog::params::run_group,
        ensure  => file,
        content => template("${module_name}/rsyslog.conf.erb"),
        require => Class["rsyslog::install"],
        notify  => Class["rsyslog::service"],
    }

    file { $rsyslog::params::rsyslog_mainmsg_queue_dir:
        owner   => root,
        group   => $rsyslog::params::run_group,
        ensure  => directory,
        require => Class["rsyslog::install"],
        notify  => Class["rsyslog::service"],
    }

    file { $rsyslog::params::rsyslog_action_queue_dir:
        owner   => root,
        group   => $rsyslog::params::run_group,
        ensure  => directory,
        require => Class["rsyslog::install"],
        notify  => Class["rsyslog::service"],
    }

if $osfamily == "Debian"
{
    file { $rsyslog::params::rsyslog_default:
        owner   => root,
        group   => $rsyslog::params::run_group,
        ensure  => file,
        source  => "puppet:///modules/rsyslog/rsyslog_default",
        require => Class["rsyslog::install"],
        notify  => Class["rsyslog::service"],
    }
}
    file { $rsyslog::params::spool_dir:
        owner   => root,
        group   => $rsyslog::params::run_group,
        ensure  => directory,
        require => Class["rsyslog::install"],
        notify  => Class["rsyslog::service"],
    }
}
