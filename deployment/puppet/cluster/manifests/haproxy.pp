# == Class: cluster::haproxy
#
# Configure HAProxy managed by corosync/pacemaker
#
class cluster::haproxy (
  $haproxy_maxconn    = '4000',
  $haproxy_bufsize    = '16384',
  $haproxy_maxrewrite = '1024',
  $primary_controller = false
) {
  include ::concat::setup
  include ::haproxy::params

  #NOTE(bogdando) we want defaults w/o chroot
  #  and this override looks the only possible if
  #  upstream manifests must be kept intact
  $global_options   = {
    'log'             => '/dev/log local0',
    'pidfile'         => '/var/run/haproxy.pid',
    'maxconn'         => $haproxy_maxconn,
    'user'            => 'haproxy',
    'group'           => 'haproxy',
    'daemon'          => '',
    'stats'           => 'socket /var/lib/haproxy/stats',
    'tune.bufsize'    => $haproxy_bufsize,
    'tune.maxrewrite' => $haproxy_maxrewrite,
  }


  class { '::haproxy':
    global_options   => $global_options,
    defaults_options => merge($::haproxy::params::defaults_options,
                              {'mode' => 'http'}),
    custom_fragment  => 'include conf.d/*.cfg',
    service_ensure   => $service_ensure,
    service_manage   => $service_manage,
  }

  class { 'cluster::haproxy_ocf':
    primary_controller => $primary_controller
  }

  Class['::haproxy'] -> Class['cluster::haproxy_ocf']

  if defined(Corosync::Service['pacemaker']) {
    Corosync::Service['pacemaker'] -> Class['cluster::haproxy_ocf']
    $service_ensure   = 'stopped'
    $service_manage   = false
    notify {"Service haproxy stopped!!":}
  } else {
    $service_ensure   = 'running'
    $service_manage   = true
    notify {"Service haproxy started!!":}
  }
}
