class monit {

  class {'monit::package':
    notify  => Class['monit::service'],
  }

  class {'monit::config':
    notify  => Class['monit::service'],
    require => Class['monit::package'],
  }

  class {'monit::service':
    require => Class['monit::config'],
  }

}
