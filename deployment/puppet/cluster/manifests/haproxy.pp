# == Class: cluster::haproxy
#
# Configure HAProxy managed by corosync/pacemaker
#
# === Parameters
#
# [*haproxy_maxconn*]
#   (optional) Max connections for haproxy
#   Defaults to '4000'
#
# [*haproxy_bufsize*]
#   (optional) Buffer size for haproxy
#   Defaults to '16384'
#
# [*haproxy_maxrewrite*]
#   (optional) Sets the reserved buffer space to this size in bytes
#   Defaults to '1024'
#
# [*haproxy_log_file*]
#   (optional) Log file location for haproxy.
#   Defaults to '/var/log/haproxy.log'
#
# [*primary_controller*]
#   (optional) Flag to indicate if this is the primary controller
#   Defaults to false
#
# [*debug*]
#   (optional)
#   Defaults to false
#
# [*other_networks*]
#   (optional)
#   Defaults to false
#
# [*stats_ipaddresses*]
#   (optional) Array of addresses to allow stats calls
#   Defaults to ['127.0.0.1']
#
class cluster::haproxy (
  $haproxy_maxconn    = '4000',
  $haproxy_bufsize    = '16384',
  $haproxy_maxrewrite = '1024',
  $haproxy_log_file   = '/var/log/haproxy.log',
  $primary_controller = false,
  $debug              = false,
  $other_networks     = false,
  $stats_ipaddresses  = ['127.0.0.1']
) {
  include ::concat::setup
  include ::haproxy::params
  include ::rsyslog::params

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
    global_options    => $global_options,
    defaults_options  => $defaults_options,
    stats_ipaddresses => $stats_ipaddresses,
    use_include       => true,
  }

  class { 'cluster::haproxy_ocf':
    primary_controller => $primary_controller,
    debug              => $debug,
    other_networks     => $other_networks,
  }

  file { '/etc/rsyslog.d/haproxy.conf':
    ensure  => present,
    content => template("${module_name}/haproxy.conf.erb"),
    notify  => Class['::rsyslog::service'],
  }

  Package['haproxy'] -> Class['haproxy::base']
  Class['haproxy::base'] -> Class['cluster::haproxy_ocf']

  if defined(Corosync::Service['pacemaker']) {
    Corosync::Service['pacemaker'] -> Class['cluster::haproxy_ocf']
  }
}
