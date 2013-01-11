class rsyslog::install {
    package { $rsyslog::params::rsyslog_package_name:
        ensure => $rsyslog::params::package_status,
    }

    package { $rsyslog::params::relp_package_name:
        ensure => $rsyslog::params::package_status
    }
}
