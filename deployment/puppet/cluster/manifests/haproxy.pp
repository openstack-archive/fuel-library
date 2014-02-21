# == Class: cluster::haproxy
#
# Configure HAProxy managed by corosync/pacemaker
#
class cluster::haproxy (
  $haproxy_maxconn = '4000',
) {
  include ::concat::setup
  include ::haproxy::params

  package { 'haproxy': } ->
  class { 'haproxy::base':
    global_options   => merge($::haproxy::params::global_options,
                              {
                                'log'     => '/dev/log local0',
                                'maxconn' => $haproxy_maxconn
                              }),
    defaults_options => merge($::haproxy::params::defaults_options,
                              {'mode' => 'http'}),
    use_include      => true,
  } ->
  class { 'cluster::haproxy_ocf': }

  Class['haproxy::base'] -> Haproxy::Service <||>

  if defined(Corosync::Service['pacemaker']) {
    Corosync::Service['pacemaker'] -> Class['cluster::haproxy_ocf']
  }
}
