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

$puppet = hiera('puppet')
class { 'puppet::pull' :
  modules_source   => $puppet['modules'],
  manifests_source => $puppet['manifests'],
}

$deployment_mode = hiera('deployment_mode')
if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  include haproxy::status
}
