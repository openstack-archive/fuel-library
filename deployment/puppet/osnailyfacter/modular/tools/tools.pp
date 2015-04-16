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
]

package { $tools :
  ensure => 'present',
}

package { 'cloud-init':
   ensure => 'purged',
}

$puppet = hiera('puppet')
class { 'puppet::pull' :
  modules_source   => $puppet['modules'],
  manifests_source => $puppet['manifests'],
}

$deployment_mode = hiera('deployment_mode')
