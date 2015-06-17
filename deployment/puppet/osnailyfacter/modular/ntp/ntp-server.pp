notice('MODULAR: ntp-server.pp')

$ntp_servers            = hiera('external_ntp')
$management_vrouter_vip = hiera('management_vrouter_vip')

class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  interfaces     => [$management_vrouter_vip],
  service_enable => false,
  service_ensure => stopped,
  iburst_enable  => true,
  tinker         => true,
  panic          => 0,
  stepout        => 5,
  minpoll        => 3,
} ->

class { 'cluster::ntp_ocf': }
