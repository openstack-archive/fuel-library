include ::ceph::params

$radosgw_service = $::ceph::params::service_radosgw

# run a restart of the radosgw service
exec { "restart-${radosgw_service}":
  command => "service ${radosgw_service} restart",
  path    => '/usr/bin:/bin:/usr/sbin:/sbin'
}

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
