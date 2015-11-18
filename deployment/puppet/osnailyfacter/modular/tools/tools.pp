notice('MODULAR: tools.pp')

class { 'osnailyfacter::atop': }
class { 'osnailyfacter::ssh': }

if $::virtual != 'physical' {
  class { 'osnailyfacter::acpid': }
}

case $::osfamily {
  'RedHat': {
    if $::operatingsystemmajrelease >= 7 {
      $man_package = 'man-db'
    } else {
      $man_package = 'man'
    }
  }
  'Debian': {
    $man_package = 'man'
  }
  default: { fail("Unsupported osfamily: ${::osfamily}") }
}

$tools = [
  'screen',
  'tmux',
  'htop',
  'tcpdump',
  'strace',
  'fuel-misc'
]

package { $man_package:
  ensure => 'present',
}

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
