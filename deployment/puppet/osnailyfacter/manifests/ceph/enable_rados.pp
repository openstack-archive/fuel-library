class osnailyfacter::ceph::enable_rados {

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

  $haproxy_stats_url = "http://${management_ip}:10000/;csv"
  $radosgw_url      = "http://${management_vip}:8080"
  $lb_defaults = { 'provider' => 'haproxy', 'url' => $haproxy_stats_url }

  $lb_backend_provider = 'http'
  $lb_url = $radosgw_url

  $lb_hash = {
    'object-storage' => {
      name     => 'object-storage',
      provider => $lb_backend_provider,
      url      => $lb_url
    }
  }

  ::osnailyfacter::wait_for_backend {'object-storage':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }

  Service[$radosgw_service] -> ::Osnailyfacter::Wait_for_backend['object-storage']
}
