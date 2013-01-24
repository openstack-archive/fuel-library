class nagios::service inherits nagios::master {

#  nagios::service::servicegroups { $servicegroups: }

  Nagios_service <<||>> {
    use     => $templateservice['name'],
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

#  Nagios_servicegroup <||> {
#    notify  => Exec['fix-permissions'],
#    require => File['conf.d'],
#  }
}
