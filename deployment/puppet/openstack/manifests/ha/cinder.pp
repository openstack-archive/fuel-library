# == Class: openstack::ha::cinder
#
# HA configuration for OpenStack Cinder
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
class openstack::ha::cinder (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl        = false,
  $public_ssl_path   = undef,
  $internal_ssl      = false,
  $internal_ssl_path = under,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }

  openstack::ha::haproxy_service { 'cinder-api':
    order                  => '070',
    listen_port            => 8776,
    public                 => true,
    public_ssl             => $public_ssl,
    public_ssl_path        => $public_ssl_path,
    internal_ssl           => $internal_ssl,
    internal_ssl_path      => $internal_ssl_path,
    require_service        => 'cinder-api',
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    define_backups         => true,
    haproxy_config_options => {
      'option'       => ['httpchk', 'httplog', 'forceclose', 'http-buffer-request'],
      'timeout'      => 'http-request 10s',
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
