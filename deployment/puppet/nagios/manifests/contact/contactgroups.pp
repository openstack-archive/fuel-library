define nagios::contact::contactgroups(
$alias = false
) {

notify {$name:}
  nagios_contactgroup { $name:
    ensure => present,
    alias  => $alias,
    target => "/etc/${nagios::params::masterdir}/${nagios::master::proj_name}/contactgroups.cfg",
  }
}
