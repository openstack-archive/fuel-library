class nagios::contact {
  $contacts = hiera('contacts')
  $contactgroups = hiera('contactgroups')

  nagios::contact::contacts { $contacts[user]:
    alias => $contacts[alias],
    email => $contacts[email],
    group => $contacts[group],
  }

  nagios::contact::contactgroups { $contactgroups[group]:
    alias => $contactgroups[alias],
  }

  Nagios_contact <||> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }

  Nagios_contactgroup <||> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }
}