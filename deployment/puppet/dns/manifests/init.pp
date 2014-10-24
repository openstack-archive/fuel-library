# == Class: dns
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
#  class { dns:
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
class dns ( $external_dns = ['8.8.8.8', '208.67.220.220'] ### for test only
###         $external_dns = $::fuel_settings['role']      ### to be set using astute
          ) {
  if $::fuel_settings['role'] =~ /controller/ {
    package { 'dnsmasq':
      ensure => installed,
    } ->

    file { '/etc/resolv.dnsmasq.conf':
      ensure  => present,
      content => template('dns/resolv.dnsmasq.conf.erb')
    } ->

    file { '/etc/dnsmasq.d/dns.conf':
      ensure  => present,
      content => template('dns/dnsmasq.conf.erb')
    } ~>

    service { 'dnsmasq':
      enable => false,
    }
  }
  
  file { '/etc/resolv.conf':
    ensure  => present,
    content => template('dns/resolv.conf.erb')
  }
}
