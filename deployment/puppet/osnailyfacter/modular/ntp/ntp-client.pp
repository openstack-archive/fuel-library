notice('MODULAR: ntp-client.pp')

$management_vip     = hiera('management_vip')

class { 'ntp':
  servers        => $management_vip,
  service_ensure => running,
  service_enable => true,
}
