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
# [*colocate_haproxy*]
#   (optional) Flag to enable pacemaker to bind haproxy to controller VIPs
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
  $haproxy_maxconn      = '4000',
  $haproxy_bufsize      = '16384',
  $haproxy_maxrewrite   = '1024',
  $haproxy_log_file     = '/var/log/haproxy.log',
  $primary_controller   = false,
  $debug                = false,
  $other_networks       = false,
  $colocate_haproxy     = false,
  $stats_ipaddresses    = ['127.0.0.1'],
  $spread_checks        = '3',
  $user_defined_options = {},
  $ssl_default_ciphers  = 'HIGH:!aNULL:!MD5:!kEDH',
  $ssl_default_options = 'no-sslv3 no-tls-tickets',
) {
  include ::haproxy::params
  include ::rsyslog::params

  package { 'haproxy':
    name => $::haproxy::params::package_name,
  }

  #NOTE(bogdando) we want defaults w/o chroot
  #  and this override looks the only possible if
  #  upstream manifests must be kept intact
  $global_options   = {
    'log'                        => '/dev/log local0',
    'pidfile'                    => '/var/run/haproxy.pid',
    'maxconn'                    => $haproxy_maxconn,
    'user'                       => 'haproxy',
    'group'                      => 'haproxy',
    'daemon'                     => '',
    'stats'                      => 'socket /var/lib/haproxy/stats',
    'spread-checks'              => $spread_checks,
    'tune.bufsize'               => $haproxy_bufsize,
    'tune.maxrewrite'            => $haproxy_maxrewrite,
    'ssl-default-bind-ciphers'   => $ssl_default_ciphers,
    'ssl-default-server-ciphers' => $ssl_default_ciphers,
    'ssl-default-bind-options'   => $ssl_default_options,
    'ssl-default-server-options' => $ssl_default_options,
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
      'dontlognull',
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

  $service_name = 'p_haproxy'

  class { '::haproxy::base':
    global_options    => merge($global_options, $user_defined_options['global']),
    defaults_options  => merge($defaults_options, $user_defined_options['defaults']),
    stats_ipaddresses => $stats_ipaddresses,
    custom_fragment   => $user_defined_options['custom_fragment'],
    use_include       => true,
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind':
    value => '1'
  }

  service { 'haproxy' :
    ensure     => 'running',
    name       => $service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  tweaks::ubuntu_service_override { 'haproxy' :
    service_name => 'haproxy',
    package_name => $haproxy::params::package_name,
  }

  class { '::cluster::haproxy::rsyslog':
    log_file => $haproxy_log_file,
  }

  Package['haproxy'] ->
  Class['haproxy::base']

  Class['haproxy::base'] ~>
  Service['haproxy']

  Package['haproxy'] ~>
  Service['haproxy']

  Sysctl::Value['net.ipv4.ip_nonlocal_bind'] ~>
  Service['haproxy']

  # Pacemaker
  class { '::cluster::haproxy_ocf':
    debug            => $debug,
    other_networks   => $other_networks,
    colocate_haproxy => $colocate_haproxy,
  }

}
