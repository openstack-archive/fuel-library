notice('MODULAR: ceph/enable_rados.pp')

include ::ceph::params

$radosgw_service       = $::ceph::params::service_radosgw
$radosgw_override_file = '/etc/init/radosgw-all.override'

if ($::operatingsystem == 'Ubuntu') {
  # ensure the service is stopped and will not start on boot
  service { 'radosgw':
    enable   => false,
    provider => 'debian',
  }

  service { 'radosgw-all':
    ensure   => running,
    enable   => true,
    provider => 'upstart',
  }

  file {$radosgw_override_file:
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => "start on runlevel [2345]\nstop on starting rc RUNLEVEL=[016]\n",
  }

  Service['radosgw'] ->
  File[$radosgw_override_file] ~>
  Service['radosgw-all']
}
else {
  service { $radosgw_service:
    ensure => running,
    enable => true,
  }
}


