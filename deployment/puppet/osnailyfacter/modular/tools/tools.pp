notice('MODULAR: tools.pp')

$custom_acct_file = hiera('custom_accounting_file', undef)
class { 'osnailyfacter::atop':
  custom_acct_file => $custom_acct_file,
}

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

$puppet = hiera('puppet')
class { 'puppet::pull' :
  modules_source   => $puppet['modules'],
  manifests_source => $puppet['manifests'],
}

$deployment_mode = hiera('deployment_mode')
