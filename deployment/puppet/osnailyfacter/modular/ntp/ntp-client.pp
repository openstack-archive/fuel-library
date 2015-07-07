notice('MODULAR: ntp-client.pp')

$ntp_servers = hiera('ntp_servers', false)

if !($ntp_servers) {
  $ntp_servers = [hiera('management_vrouter_vip'),]
}

class { 'ntp':
  servers        => $ntp_servers,
  interfaces     => ['lo'],
  service_ensure => running,
  service_enable => true,
  iburst_enable  => true,
  tinker         => true,
  panic          => 0,
  stepout        => 5,
  minpoll        => 3,
}
