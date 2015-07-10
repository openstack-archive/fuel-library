notice('MODULAR: ironic/conductor.pp')

package { 'ipmitool':
  ensure => present,
}

class { '::ironic::conductor':
  require => Package['ipmitool'],
}
