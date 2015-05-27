notice('MODULAR: tools.pp')

class { 'osnailyfacter::atop': }

class { 'osnailyfacter::ssh': }

$tools = [
  'screen',
  'tmux',
  'man',
  'htop',
  'tcpdump',
  'strace',
  'fuel-misc'
]

package { $tools :
  ensure => 'present',
}

package { 'cloud-init':
  ensure => 'purged',
}

if !defined(Package['irqbalance']) {
  package { 'irqbalance':
    ensure => installed,
  }
}

if !defined(Service['irqbalance']) {
  service { 'irqbalance':
    ensure => running,
  }
}

$puppet = hiera('puppet')
class { 'puppet::pull' :
  modules_source   => $puppet['modules'],
  manifests_source => $puppet['manifests'],
}

$deployment_mode = hiera('deployment_mode')
