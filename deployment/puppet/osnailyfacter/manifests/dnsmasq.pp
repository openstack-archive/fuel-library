# == Class: osnailyfacter::dnsmasq
#
# Configure DNS on fuel controller nodes
#
# === Parameters
#
# [*$external_dns*]
# Array of DNS servers that will be used for resolving external queries
#
# [*$master_ip*]
# Ip address of fuel master node
#
# [*$management_vrouter_vip*]
# IP address of management interface in vrouter namespace
#
# === Examples
#
#  class { osnailyfacter::dnsmasq:
#    external_dns           => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    master_ip              => '1.1.1.1',
#    management_vrouter_vip => '1.2.3.4'
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
class osnailyfacter::dnsmasq (
  $external_dns,
  $master_ip,
  $management_vrouter_vip,
) {
  $package_name = $osfamily ? {
    /(RedHat|CentOS)/ => 'dnsmasq',
    /(Debian|Ubuntu)/ => 'dnsmasq-base',
    default           => 'dnsmasq',
  }

  ensure_packages($package_name)
  validate_array($external_dns)

  file { '/etc/dnsmasq.d':
    ensure => directory,
  }

  file { '/etc/resolv.dnsmasq.conf':
    ensure  => present,
    content => template('osnailyfacter/resolv.dnsmasq.conf.erb'),
  } ->

  file { '/etc/dnsmasq.d/dns.conf':
    ensure  => present,
    content => template('osnailyfacter/dnsmasq.conf.erb'),
  }
}
