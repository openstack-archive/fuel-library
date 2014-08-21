class osnailyfacter::package_ensure {
  if $::osfamily == 'Debian' {
    $ensure_list = [
      'python-oslo-messaging',
      'python-kombu',
    ]
  } elsif $::osfamily == 'RedHat' {
    $ensure_list = [
      'python-oslo-messaging',
      'python-kombu',
    ]
  } else {
    $ensure_list = []
  }

  package { $ensure_list :
    ensure => installed,
  }

  Package[$ensure_list] -> Service <||>

}
