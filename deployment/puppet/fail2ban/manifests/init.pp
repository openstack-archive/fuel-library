class fail2ban (
  $jails = [],
  $mailto = undef
) inherits params {
    file { $fail2ban::params::config_file:
        owner   => root,
        group   => root,
        mode    => 644,
        content => template('fail2ban/fail2ban.erb'),
        require => Package[$fail2ban::params::package],
        notify  => Service[$fail2ban::params::service]
    }
    file { $fail2ban::params::jail_file:
        owner   => root,
        group   => root,
        mode    => 644,
        content => template('fail2ban/jail.erb'),
        require => Package[$fail2ban::params::package],
        notify  => Service[$fail2ban::params::service]
    }
    package { $fail2ban::params::package: ensure => latest }
    service { $fail2ban::params::service:
        ensure => running,
        enable => true,
        hasrestart => true,
        require => Package[$fail2ban::params::package]
    }
}
