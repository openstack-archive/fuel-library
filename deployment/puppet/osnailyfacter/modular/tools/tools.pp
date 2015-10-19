notice('MODULAR: tools.pp')

class { 'osnailyfacter::atop': }
class { 'osnailyfacter::ssh': }

if $::virtual != 'physical' {
  class { 'osnailyfacter::acpid': }
}

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
  ensure => 'absent',
}

if $::osfamily == 'Debian' {
  apt::conf { 'notranslations':
    ensure        => 'present',
    content       => 'Acquire::Languages "none";',
    notify_update => false,
  }
}

$puppet = hiera('puppet')
class { 'osnailyfacter::puppet_pull':
  modules_source   => $puppet['modules'],
  manifests_source => $puppet['manifests'],
}

$deployment_mode = hiera('deployment_mode')
