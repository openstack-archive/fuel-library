# == Class: osnailyfacter::dns
#
# Configure DNS and resolv.conf for fuel nodes
#
# === Parameters
#
# [*$external_dns*]
# Array of DNS servers that will be used for resolving external queries
#
# === Examples
#
#  class { osnailyfacter::dns:
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
class osnailyfacter::dns ( $external_dns,
                           $master_ip,
                           $management_vip ) {
  if $::fuel_settings['role'] =~ /controller/ {
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
  
  file { '/etc/resolv.conf':
    ensure  => present,
    content => template('osnailyfacter/resolv.conf.erb')
  }
}
