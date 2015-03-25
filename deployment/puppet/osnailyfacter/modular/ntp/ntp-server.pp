notice('MODULAR: ntp-server.pp')

$ntp_servers        = hiera('external_ntp')
$primary_controller = hiera('primary_controller')

class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  service_enable => false,
  service_ensure => stopped,
} ->

class { 'cluster::ntp_ocf':
  primary_controller => $primary_controller,
}
