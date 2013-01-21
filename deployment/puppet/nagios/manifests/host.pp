class nagios::host {
  $hostgroups = hiera('hostgroups')

  nagios::host::hostgroups { $hostgroups: }

  Nagios_host <<||>> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

  Nagios_hostgroup <||> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

  Nagios_hostextinfo <<||>> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }
}