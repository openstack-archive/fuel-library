# == Class: osnailyfacter::resolvconf
#
# Configure resolv.conf on fuel nodes
#
# === Parameters
#
# [*$management_vip*]
# Management virtual ip address
#
# === Examples
#
#  class { osnailyfacter::resolvconf:
#    management_vip => '1.1.1.1',
#  }
#
# === Authors
#
# Mirantis
#
# === Copyright
#
# GNU GPL
#
class osnailyfacter::resolvconf (
  $management_vip
) {
  $file_path = $::osfamily ? {
    /(RedHat|CentOS)/ => '/etc/resolv.conf',
    /(Debian|Ubuntu)/ => '/etc/resolvconf/resolv.conf.d/head',
    default           => '/etc/resolv.conf',
  }

  file { $file_path:
    ensure  => file,
    content => template('osnailyfacter/resolv.conf.erb')
  }

  if $::osfamily =~ /(Debian|Ubuntu)/ {
    package { 'resolvconf':
      ensure => present,
    } ->
    file { '/etc/resolv.conf':
      ensure => link,
      target => '/run/resolvconf/resolv.conf',
    } ~>
    exec { 'dpkg-reconfigure resolvconf':
      command     => '/usr/sbin/dpkg-reconfigure -f noninteractive resolvconf',
      refreshonly => true,
    }
    file {'/etc/default/resolvconf':
      content => 'REPORT_ABSENT_SYMLINK="yes"',
    }
    service { 'resolvconf':
      ensure    => running,
      enable    => true,
      subscribe => [ File[$file_path], File['/etc/default/resolvconf'], ]
    }
  }
}
