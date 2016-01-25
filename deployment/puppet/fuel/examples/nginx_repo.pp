notice('MODULAR: nginx_repo.pp')

case $::osfamily {
  'RedHat': {
    if ($::operatingsystemrelease =~ /^7.*/) {
      $service_enabled = true
    } else {
      $service_enabled = false
    }
  }
  default: { $service_enabled = false }
}

node default {
  class { '::fuel::nginx::repo':
    service_enabled => $service_enabled,
  }
}
