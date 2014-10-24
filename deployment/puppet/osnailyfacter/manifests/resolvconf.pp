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
#    external_dns => '1.1.1.1',
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
  file { '/etc/resolv.conf':
    ensure  => present,
    content => template('osnailyfacter/resolv.conf.erb')
  }
}
