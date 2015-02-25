class rsyslog::install {
  if $rsyslog::params::rsyslog_package_name {
    package { $rsyslog::params::rsyslog_package_name:
        ensure => $rsyslog::params::package_status,
    }
  }

  if $rsyslog::params::relp_package_name {
    package { $rsyslog::params::relp_package_name:
        ensure => $rsyslog::params::package_status
    }
  }
  if $rsyslog::params::additional_packages {
    package { $rsyslog::params::rsyslog_additional_packages:
        ensure => $rsyslog::params::package_status
    }
  }
}
