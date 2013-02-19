define nagios::host::hostgroups() {

  $alias = inline_template('<%= name.capitalize -%>')

  nagios_hostgroup { $name:
    ensure         => present,
    alias          => $alias,
    target         => "/etc/${nagios::params::masterdir}/${nagios::proj_name}/hostgroups.cfg",
  }
}
