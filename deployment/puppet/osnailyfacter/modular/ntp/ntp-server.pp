notice('MODULAR: ntp-server.pp')

$ntp_servers = hiera('external_ntp')
$management_vrouter_vip = hiera('management_vrouter_vip')

class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  interfaces     => ['lo', 'vr-ns', $management_vrouter_vip],
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
  tweaks::ubuntu_service_override { 'nova-cert':
    package_name => $ntp::params::package_name,
    service_name => $ntp::params::service_name,
  }
}
