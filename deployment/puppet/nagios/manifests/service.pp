class nagios::service {
  $servicegroups = hiera('servicegroups')

  nagios::service::servicegroups { $servicegroups: }

  Nagios_service <<||>> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

  Nagios_servicegroup <||> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }
}