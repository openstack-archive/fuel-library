notice('MODULAR: ntp-server.pp')

$ntp_servers = hiera('external_ntp')

class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  service_enable => false,
  service_ensure => 'stopped',
  iburst_enable  => true,
  tinker         => true,
  panic          => '0',
  stepout        => '5',
  minpoll        => '3',
} ->

class { 'cluster::ntp_ocf': }

if $::operatingsystem == 'Ubuntu' {
  include ntp::params
  tweaks::ubuntu_service_override { 'ntpd':
    package_name => $ntp::params::package_name,
    service_name => $ntp::params::service_name,
  }
}
