notice('MODULAR: tools.pp')

class { 'osnailyfacter::atop': }

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

class { 'puppet::pull' :
  modules_source   => hiera('puppet_modules_source','/etc/puppet/modules/'),
  manifests_source => hiera('puppet_manifests_source','/etc/puppet/manifests/'),
}

$deployment_mode = hiera('deployment_mode')
if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  include haproxy::status
}
