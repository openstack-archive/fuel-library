class osnailyfacter::tools::tools {

  notice('MODULAR: tools/tools.pp')

  $atop_hash     = hiera('atop', {})
  $atop_enabled  = pick($atop_hash['service_enabled'], true)
  $atop_interval = pick($atop_hash['interval'], 20)
  $atop_rotate   = pick($atop_hash['rotate'], 7)

  $custom_acct_file = hiera('custom_accounting_file', undef)

  $puppet = hiera('puppet')
  $deployment_mode = hiera('deployment_mode')

  # improve overall performance of the node
  sysctl::value { 'vm.swappiness': value => '10' }

  class { '::osnailyfacter::atop':
    service_enabled  => $atop_enabled,
    interval         => $atop_interval,
    rotate           => $atop_rotate,
    custom_acct_file => $custom_acct_file,
  }

  class { '::osnailyfacter::ssh': }

  ensure_packages(['postfix'])

  service { 'postfix':
    ensure  => running,
    enable  => true,
    require => Package['postfix'],
  }

  augeas { 'configure postfix':
    context => '/files/etc/postfix/main.cf',
    changes => [
      "set /files/etc/postfix/main.cf/mydestination ${::fqdn},localhost",
      "set /files/etc/postfix/main.cf/myhostname ${::fqdn}",
      'set /files/etc/postfix/main.cf/inet_interfaces loopback-only',
      'set /files/etc/postfix/main.cf/default_transport error',
      'set /files/etc/postfix/main.cf/relay_transport error',
    ],
    notify  => Service['postfix'],
    require => Package['postfix'],
  }

  if $::virtual != 'physical' {
    class { '::osnailyfacter::acpid': }
  }

  $tools = [
    'screen',
    'tmux',
    'htop',
    'tcpdump',
    'strace',
    'fuel-misc',
    'man-db',
  ]

  $cloud_init_services = [
    'cloud-config',
    'cloud-final',
    'cloud-init',
    'cloud-init-container',
    'cloud-init-local',
    'cloud-init-nonet',
    'cloud-log-shutdown',
  ]

  if ($::operatingsystem == 'Ubuntu') {
    service { $cloud_init_services:
      enable => false,
    }
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

  class { '::osnailyfacter::puppet_pull':
    modules_source   => $puppet['modules'],
    manifests_source => $puppet['manifests'],
  }
}
