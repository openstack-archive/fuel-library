# == Class: cluster::haproxy
#
# Configure HAProxy managed by corosync/pacemaker
#
class cluster::haproxy (
  $haproxy_maxconn    = '4000',
  $haproxy_bufsize    = '16384',
  $haproxy_maxrewrite = '1024',
  $primary_controller = false,
  $debug              = false
) {
  include ::concat::setup
  include ::haproxy::params

  package { 'haproxy': }

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

  $defaults_options = {
    'log'     => 'global',
    'stats'   => 'enable',
    'maxconn' => '8000',
    'mode'   => 'http',
    'retries' => '3',
    'option'  => [
      'redispatch',
      'http-server-close',
      'splice-auto',
    ],
    'timeout' => [
      'http-request 20s',
      'queue 1m',
      'connect 10s',
      'client 1m',
      'server 1m',
      'check 10s',
    ],
  }

  class { 'haproxy::base':
    global_options   => $global_options,
    defaults_options => $defaults_options,
    use_include      => true,
  }

  class { 'cluster::haproxy_ocf':
    primary_controller => $primary_controller,
    debug              => $debug
  }

  Package['haproxy'] -> Class['haproxy::base']
  Class['haproxy::base'] -> Class['cluster::haproxy_ocf']
  Class['haproxy::base'] -> Haproxy::Service <||>

  if defined(Corosync::Service['pacemaker']) {
    Corosync::Service['pacemaker'] -> Class['cluster::haproxy_ocf']
  }
}
