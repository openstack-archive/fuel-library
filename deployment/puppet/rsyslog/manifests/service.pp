class rsyslog::service {
    service { $rsyslog::params::service_name:
        ensure  => running,
        enable  => true,
        require => Class["rsyslog::config"],
    }
}
