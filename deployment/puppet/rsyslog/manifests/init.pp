class rsyslog {
# assumes rsyslog packages installed at BM stage or included in distro
    include rsyslog::params, rsyslog::config, rsyslog::service
}
