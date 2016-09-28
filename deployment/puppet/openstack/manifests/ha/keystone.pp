# == Class: openstack::ha::keystone
#
# HA configuration for OpenStack Keystone
#
# === Parameters
#
# [*internal_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the internal facing
#   vip
#
# [*ipaddresses*]
#   (required) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
#
# [*public_ssl*]
#   (optional) Boolean. If true, enables SSL for $public_virtual_ip
#   Defaults to false.
#
# [*public_ssl_path*]
#   (optional) String. Filesystem path to the file with public certificate
#   content
#   Defaults to undef
#
# [*internal_ssl*]
#   (optional) Boolean. If true, enables SSL for $internal_virtual_ip and port
#   5000
#   Defaults to false.
#
# [*internal_ssl_path*]
#   (optional) String. Filesystem path to the file with internal certificate
#   content
#   Defaults to undef
#
# [*admin_ssl*]
#   (optional) Boolean. If true, enables SSL for $internal_virtual_ip and port
#   35357
#   Defaults to false.
#
# [*admin_ssl_path*]
#   (optional) String. Filesystem path to the file with admin certificate
#   content
#   Defaults to undef
#
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
# [*federation_enabled*]
#   (Optional) If enabled, sticky sessions will be enabled for keystone sessions
#   to properly support federation.
#
class openstack::ha::keystone (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl         = false,
  $public_ssl_path    = undef,
  $internal_ssl       = false,
  $internal_ssl_path  = undef,
  $admin_ssl          = false,
  $admin_ssl_path     = undef,
  $federation_enabled = false,
) {

  $base_options = {
    'option'       => ['httpchk GET /v3', 'httplog', 'forceclose', 'http-buffer-request', 'forwardfor'],
    'timeout'      => 'http-request 10s',
    'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
  }

  if $federation_enabled {
    # See LP#1527717
    $session_options = {
      'stick'       => ['on src'],
      'stick-table' => ['type ip size 200k expire 2m'],
    }
  } else {
    $session_options = { }
  }

  $config_options = merge($base_options, $session_options)

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public_ssl             => $public_ssl,
    public_ssl_path        => $public_ssl_path,
    internal_ssl           => $internal_ssl,
    internal_ssl_path      => $internal_ssl_path,
    haproxy_config_options => $config_options,
    balancermember_options => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
  }

  openstack::ha::haproxy_service { 'keystone-1':
    order       => '020',
    listen_port => 5000,
    public      => true,
    public_ssl  => $public_ssl,
  }

  openstack::ha::haproxy_service { 'keystone-2':
    order             => '030',
    listen_port       => 35357,
    public            => false,
    internal_ssl      => $admin_ssl,
    internal_ssl_path => $admin_ssl_path,
  }
}
