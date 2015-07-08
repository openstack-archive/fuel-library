include ::ceph::params

$radosgw_service = $::ceph::params::service_radosgw

# ensure the service is running and will start on boot
service { $radosgw_service:
  ensure => running,
  enable => true,
}

# The Ubuntu upstart script is incompatible with the upstart provider
#  This will force the service to fall back to the debian init script
if ($::operatingsystem == 'Ubuntu') {
  Service['radosgw'] {
    provider => 'debian'
  }
}
