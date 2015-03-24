notice('MODULAR: ntp-server.pp')

$ntp_servers        = hiera('external_ntp')
$primary_controller = hiera('primary_controller')

class { 'ntp':
  servers        => strip(split($ntp_servers['ntp_list'], ',')),
  service_enable => false,
  service_ensure => stopped,
  config         => '/etc/ntp.server.conf',
} ->

file { '/var/lib/ntp/controller-server':
  content => '# Do not delete, it is a flag for multi-role deploy',
} ->

class { 'cluster::ntp_ocf':
  primary_controller => $primary_controller,
}

