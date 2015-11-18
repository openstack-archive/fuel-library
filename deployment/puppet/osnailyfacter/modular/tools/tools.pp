notice('MODULAR: tools.pp')

class { 'osnailyfacter::atop': }
class { 'osnailyfacter::ssh': }

if $::virtual != 'physical' {
  class { 'osnailyfacter::acpid': }
}

case $::osfamily {
  'RedHat': {
    $man_package = 'man-db'
  }
  'Debian': {
    $man_package = 'man'
  }
  default: { fail("Unsupported osfamily: ${::osfamily}") }
}

$tools = [
  'screen',
  'tmux',
  $man_package,
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
