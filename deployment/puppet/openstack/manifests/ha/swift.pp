# == Class: openstack::ha::swift
#
# HA configuration for OpenStack Swift
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
# [*baremetal_virtual_ip*]
#   (optional) String. This is the ipaddress to be used for the baremetal facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
# [*bind_to_one*]
#   (optional) Boolean. If false, uses custom script checker w/ additional tests
#   Defaults to true.
#
class openstack::ha::swift (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl           = false,
  $public_ssl_path      = undef,
  $internal_ssl         = false,
  $internal_ssl_path    = undef,
  $baremetal_virtual_ip = undef,
  $bind_to_one          = true,
) {

  $bm_opt_tail = 'inter 15s fastinter 2s downinter 8s rise 3 fall 3'

  if $bind_to_one {
    $http_check = 'httpchk HEAD /healthcheck HTTP/1.0'
    $balancermember_options = "check ${bm_opt_tail}"
  } else {
    $http_check = 'httpchk'
    $balancermember_options = "check port 49001 ${bm_opt_tail}"
  }

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    listen_port            => 8080,
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    haproxy_config_options => {
      'option'       => [
        $http_check,
        'httplog',
        'forceclose',
        'http-buffer-request',
        'tcp-smart-accept',
        'tcp-smart-connect',
      ],
      'timeout'      => 'http-request 10s',
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
    balancermember_options => $balancermember_options,
  }

  openstack::ha::haproxy_service { 'object-storage':
    order             => '130',
    public            => true,
    public_ssl        => $public_ssl,
    public_ssl_path   => $public_ssl_path,
    internal_ssl      => $internal_ssl,
    internal_ssl_path => $internal_ssl_path,
  }

  if $baremetal_virtual_ip {
    openstack::ha::haproxy_service { 'object-storage-baremetal':
      order               => '135',
      public_virtual_ip   => false,
      internal_virtual_ip => $baremetal_virtual_ip,
    }
  }
}
