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

# TODO(bpiotrowski): switch to apt::conf when we upgrade to puppetlabs/apt 2.2.x
if $::osfamily == 'Debian' {
  $content = 'Acquire::Languages "none";'
  apt::setting { 'conf-notranslations':
    ensure        => 'present',
    priority      => '50',
    content       => template('apt/_conf_header.erb', 'apt/conf.erb'),
    notify_update => false,
  }
}

$puppet = hiera('puppet')
class { 'puppet::pull' :
  modules_source   => $puppet['modules'],
  manifests_source => $puppet['manifests'],
}

$deployment_mode = hiera('deployment_mode')
