notice('MODULAR: ntp.pp')

$role               = hiera('role')
$ntp_servers        = hiera('external_ntp')
$management_vip     = hiera('management_vip')
$primary_controller = hiera('primary_controller')

if $role =~ /controller/ {
  class { 'ntp':
    servers        => strip(split($ntp_servers['ntp_list'], ',')),
    package_name   => ['ntp-dev'],
    service_enable => false,
    service_ensure => stopped,
  } ->

  class { 'cluster::ntp_ocf':
    primary_controller => $primary_controller,
  }

  #### to be removed when vrouters implemented ####
  Class['cluster::haproxy'] -> Class['cluster::ntp_ocf']
}
else {
  class { 'ntp':
    servers        => $management_vip,
    package_name   => ['ntp-dev'],
    service_ensure => running,
    service_enable => true,
  }
}
