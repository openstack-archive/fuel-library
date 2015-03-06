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

$puppet = hiera('puppet', false)

# FIXME: when nailgun API is updated remove conditional and
# leave only $puppet hash part
if is_hash($puppet) {
  class { 'puppet::pull' :
    modules_source   => $puppet['modules'],
    manifests_source => $puppet['manifests'],
  }
} else {
  class { 'puppet::pull' :
    modules_source   => hiera('puppet_modules_source'),
    manifests_source => hiera('puppet_manifests_source'),
  }
}

$deployment_mode = hiera('deployment_mode')
if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  include haproxy::status
}
