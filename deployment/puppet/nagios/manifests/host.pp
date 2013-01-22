class nagios::host inherits nagios::master {

  #nagios::host::hostgroups { $hostgroups['hostgroup_name']:
  #  proj_name => $proj_name,
  #  members   => $hostgroups[members],
  #}

  Nagios_host <<||>> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

  #Nagios_hostgroup <<||>> {
  #  notify  => Exec['fix-permissions'],
  #  require => File['conf.d'],
  #}

  Nagios_hostextinfo <<||>> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }
}
