class rsyslog {
    include rsyslog::params, rsyslog::install, rsyslog::config, rsyslog::checksum_udp514, rsyslog::service
}
