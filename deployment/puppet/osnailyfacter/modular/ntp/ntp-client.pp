notice('MODULAR: ntp-client.pp')

$ntp_servers             = hiera_array('ntp_servers')
$nodes_hash              = hiera('nodes', {})
$roles                   = node_roles($nodes_hash, hiera('uid'))


class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  service_ensure => 'running',
  service_enable => true,
  iburst_enable  => true,
  tinker         => true,
  panic          => '0',
  stepout        => '5',
  minpoll        => '3',
}

include ntp::params
tweaks::ubuntu_service_override { 'ntpd':
  package_name => $ntp::params::package_name,
  service_name => $ntp::params::service_name,
}
