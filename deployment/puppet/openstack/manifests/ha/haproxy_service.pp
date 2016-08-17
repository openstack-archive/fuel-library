# == Type: openstack::ha::haproxy_service
#
# Register a service with HAProxy
#
# === Parameters
#
# [*internal_virtual_ip*]
#   (required) Array or Single value. This is the ipaddress to be used for the internal facing
#   vip
#
# [*ipaddresses*]
#   (optional) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
#
# [*order*]
#   (required) String. Number or string used for configuration file ordering.
#   vip
#
# [*public_virtual_ip*]
#   (optional) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (optional) Array. This is an array of server names for the haproxy service
#
# [*balancemember_options*]
#   (optional) String or Array. Options for the balancermember configuration.
#   Defaults to 'check'
#
# [*balancemember_port*]
#   (optional) Integer.
#   Defaults to the value of the $listen_port parameter
#
# [*define_backups*]
#   (optional) Boolean. Use active-passive failover, mark all backends except
#   the first one as backups
#   Defaults to false
#
# [*define_cookies*]
#   (optional) Boolean. If true, then add a serviceid cookie for stickiness.
#   Defaults to false
#
# [*haproxy_config_options*]
#   (optional) Hash. HAProxy configuration options for the service.
#   Defaults to { 'option' => ['httplog'], 'balance' => 'roundrobin'}
#
# [*internal*]
#   (optional) Boolean. If set to true listen on the $interanl_vip_ip
#   Defaults to true.
#
# [*mode*]
#   (optional) String. The mode of operation for the service. Valid values are
#   undef, 'tcp', 'http', and 'health'
#   Defaults to undef
#
# [*public*]
#   (optional) Boolean. If true, listen on the $public_virtual_ip.
#   Defaults to false.
#
# [*public_ssl*]
#   (optional) Boolean. If true, enable SSL on $public_virtual_ip.
#   Defaults to false.
# [*require_service*]
#   (optional) Boolean. If true, refresh service before registering in HAProxy.
#   Defaults to false.
# [*before_start*]
#   (optional) Boolean. If true, service is configured before starting HAProxy service.
#   This will cause an error if service does not start. Usually not needed for
#   'listen Stats' directive.
#   Defaults to false.
define openstack::ha::haproxy_service (
  $internal_virtual_ip,
  $listen_port,
  $order,
  $public_virtual_ip      = undef,
  $balancermember_options = 'check',
  $balancermember_port    = $listen_port,
  $before_start           = false,
  $define_backups         = false,
  $define_cookies         = false,
  $haproxy_config_options = { 'option'  => ['httplog', 'forceclose', 'http-buffer-request'],
                              'timeout' => 'http-request 10s',
                              'balance' => 'roundrobin' },
  $internal               = true,
  $public                 = false,
  $ipaddresses            = undef,
  $server_names           = undef,
  $mode                   = undef,
  $public_ssl             = false,
  $public_ssl_path        = undef,
  $internal_ssl           = false,
  $internal_ssl_path      = undef,
  $require_service        = undef,
) {

  validate_bool($define_backups)
  validate_bool($define_cookies)
  validate_bool($public)
  validate_bool($internal)

  include ::openstack::ha::haproxy_restart

  if $public_ssl and !$public_ssl_path {
    fail('You must set up path to public ssl keypair if you want to use public ssl')
  }
  if $internal_ssl and !$internal_ssl_path {
    fail('You must set up path to internal ssl keypair if you want to use internal ssl')
  }
  if !($internal or $public) {
    fail('At least one of $public or $internal must be set to true')
  }

  if $public {
    $public_bind_address = suffix(any2array($public_virtual_ip), ":${listen_port}")
    if $public_ssl {
      $public_bind = array_to_hash($public_bind_address, ['ssl', 'crt', $public_ssl_path])
    } else {
      $public_bind = array_to_hash($public_bind_address, '')
    }
  } else {
    $public_bind = {}
  }

  if $internal {
    $internal_bind_address = suffix(any2array($internal_virtual_ip), ":${listen_port}")
    if $internal_ssl {
      $internal_bind = array_to_hash($internal_bind_address, ['ssl', 'crt', $internal_ssl_path])
    } else {
      $internal_bind = array_to_hash($internal_bind_address, '')
    }
  } else {
    $internal_bind = {}
  }

  # Get additional haproxy configuration options from hiera
  $haproxy_config_options_hash = hiera_hash('haproxy_config_options', {})

  # Merge selected by $name hash from hiera and one from upstream resource
  $merged_config_options = merge($haproxy_config_options, pick($haproxy_config_options_hash[$name], {}))

  # Configure HAProxy to listen
  haproxy::listen { $name:
    order       => $order,
    bind        => merge($public_bind, $internal_bind),
    options     => $merged_config_options,
    mode        => $mode,
    use_include => true,
    notify      => Exec['haproxy-restart'],
  }

  if $ipaddresses and $server_names {
    haproxy::balancermember { $name:
      order             => $order,
      listening_service => $name,
      server_names      => $server_names,
      ipaddresses       => $ipaddresses,
      ports             => $balancermember_port,
      options           => $balancermember_options,
      define_cookies    => $define_cookies,
      define_backups    => $define_backups,
      use_include       => true,
      notify            => Exec['haproxy-restart'],
    }
  }
}
