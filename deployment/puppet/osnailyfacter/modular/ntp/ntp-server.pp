notice('MODULAR: ntp-server.pp')

$ntp_servers        = hiera('external_ntp')

class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  service_enable => false,
  service_ensure => stopped,
} ->

class { 'cluster::ntp_ocf':
  primary_controller => true,
}
