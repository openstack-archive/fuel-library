define nagios::contact::contactgroups($alias = false) {
  nagios_contactgroup { $name:
    ensure => present,
    alias  => $alias,
    target => '/etc/nagios3/conf.d/contactgroups.cfg',
  }
}