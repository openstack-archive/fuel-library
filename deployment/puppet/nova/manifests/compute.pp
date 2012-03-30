#schedulee this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute(
  $enabled = false,
) {

  Exec['post-nova_config'] ~> Service['nova-compute']
  Exec['nova-db-sync']  ~> Service['nova-compute']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if($::nova::params::compute_package_name != undef) {
    package { 'nova-compute':
      name   => $::nova::params::compute_package_name,
      ensure => present,
      notify => Service['nova-compute'],
    }
  }

  service { "nova-compute":
    name => $::nova::params::compute_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::common_package_name],
    before  => Exec['networking-refresh'],
  }
}
