class nagios::contact inherits nagios::master {

  nagios::contact::contacts { $contacts[user]:
    alias   => $contacts[alias],
    email   => $contacts[email],
    group   => $contacts[group],
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

  nagios::contact::contactgroups { $contactgroups[group]:
    alias   => $contactgroups[alias],
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

#  Nagios_contact <||> {
#    notify  => Exec['fix-permissions'],
#    require => File['conf.d'],
#  }
#
#  Nagios_contactgroup <||> {
#    notify  => Exec['fix-permissions'],
#    require => File['conf.d'],
#  }
}
