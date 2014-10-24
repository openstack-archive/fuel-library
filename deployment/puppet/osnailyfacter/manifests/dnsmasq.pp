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
# === Examples
#
#  class { osnailyfacter::dnsmasq:
#    external_dns => [ 'pool.ntp.org', 'ntp.local.company.com' ],
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
  $master_ip 
) {
  package { 'dnsmasq':
    ensure => installed,
  } ->

  file { '/etc/resolv.dnsmasq.conf':
    ensure  => present,
    content => template('osnailyfacter/resolv.dnsmasq.conf.erb')
  } ->

  file { '/etc/dnsmasq.d/dns.conf':
    ensure  => present,
    content => template('osnailyfacter/dnsmasq.conf.erb')
  } ~>

  service { 'dnsmasq':
    enable => false,
  }
}

