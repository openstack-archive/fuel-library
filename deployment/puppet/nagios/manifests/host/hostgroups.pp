define nagios::host::hostgroups() {
  $alias = inline_template('<%= name.capitalize -%>')

  nagios_hostgroup { $name:
    ensure => present,
    alias  => $alias,
    target => '/etc/nagios3/conf.d/hostgroups.cfg',
  }
}