# == Class: openstack::ha::aodh
#
# HA configuration for OpenStack Aodh
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
# [*listen_port*]
#   (optional) The aodh api port.
#   Defaults to 8042
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
#   (optional) Boolean. If true, enables SSL for $internal_virtual_ip
#   Defaults to false.
#
# [*internal_ssl_path*]
#   (optional) String. Filesystem path to the file with internal certificate
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
class openstack::ha::aodh (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $listen_port       = '8042',
  $public_ssl        = false,
  $public_ssl_path   = undef,
  $internal_ssl      = false,
  $internal_ssl_path = undef,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }

  openstack::ha::haproxy_service { 'aodh':
    order                  => '135',
    listen_port            => $listen_port,
    public                 => true,
    public_ssl             => $public_ssl,
    public_ssl_path        => $public_ssl_path,
    internal_ssl           => $internal_ssl,
    internal_ssl_path      => $internal_ssl_path,
    require_service        => 'aodh-api',
    haproxy_config_options => {
      'option'       => ['httplog', 'forceclose', 'http-buffer-request'],
      'timeout'      => 'http-request 10s',
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
  }
}

