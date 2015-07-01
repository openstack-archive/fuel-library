notice('MODULAR: ntp-client.pp')

$management_vrouter_vip  = hiera('management_vrouter_vip')
$internal_address        = hiera('internal_address')
$nodes_hash              = hiera('nodes', {})

class { 'ntp':
  servers        => [$management_vrouter_vip],
  interfaces     => ['lo', $internal_address],
  service_ensure => 'running',
  service_enable => true,
  iburst_enable  => true,
  tinker         => true,
  panic          => '0',
  stepout        => '5',
  minpoll        => '3',
}

if $::operatingsystem == 'Ubuntu' {
  include ntp::params
  tweaks::ubuntu_service_override { 'nova-cert':
    package_name => $ntp::params::package_name,
    service_name => $ntp::params::service_name,
  }
}
