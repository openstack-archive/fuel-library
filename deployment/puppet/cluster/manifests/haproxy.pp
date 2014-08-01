# == Class: cluster::haproxy
#
# Configure HAProxy managed by corosync/pacemaker
#
class cluster::haproxy (
  $haproxy_maxconn = '4000',
  $primary_controller = false
) {
  include ::concat::setup
  include ::haproxy::params

  package { 'haproxy': }

  #NOTE(bogdando) we want defaults w/o chroot
  #  and this override looks the only possible if
  #  upstream manifests must be kept intact
  $global_options   = {
    'log'     => '/dev/log local0',
    'pidfile' => '/var/run/haproxy.pid',
    'maxconn' => $haproxy_maxconn,
    'user'    => 'haproxy',
    'group'   => 'haproxy',
    'daemon'  => '',
    'stats'   => 'socket /var/lib/haproxy/stats',
  }

  class { 'haproxy::base':
    global_options   => $global_options,
    defaults_options => merge($::haproxy::params::defaults_options,
                              {'mode' => 'http'}),
    use_include      => true,
  }

  class { 'cluster::haproxy_ocf':
    primary_controller => $primary_controller
  }

  Package['haproxy'] -> Class['haproxy::base']
  Class['haproxy::base'] -> Class['cluster::haproxy_ocf']
  Class['haproxy::base'] -> Haproxy::Service <||>

  if defined(Corosync::Service['pacemaker']) {
    Corosync::Service['pacemaker'] -> Class['cluster::haproxy_ocf']
  }
}
