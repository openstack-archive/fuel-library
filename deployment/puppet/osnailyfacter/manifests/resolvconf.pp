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
### Need a fix for Ubuntu ###
#    /(Debian|Ubuntu)/ => '/etc/resolvconf/resolv.conf.d/head',
    /(Debian|Ubuntu)/ => '/etc/resolv.conf',
    default           => '/etc/resolv.conf',
  }

  file { $file_path:
    ensure  => present,
    content => template('osnailyfacter/resolv.conf.erb')
  }

  if $::osfamily =~ /(Debian|Ubuntu)/ {
    service { 'resolvconf':
      ensure    => running,
      enable    => true,
      subscribe => File[$file_path],
    }
  }
}
