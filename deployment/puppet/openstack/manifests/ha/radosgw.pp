# == Class: openstack::ha::radosgw
#
# HA configuration for radosgw
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
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
class openstack::ha::radosgw (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl           = false,
  $public_ssl_path      = undef,
  $baremetal_virtual_ip = undef,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    listen_port            => 8080,
    balancermember_port    => 7480,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    haproxy_config_options => {
      'option'       => ['httplog', 'httpchk HEAD /', 'forceclose', 'forwardfor', 'http-buffer-request'],
      'timeout'      => 'http-request 10s',
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
  }

  openstack::ha::haproxy_service { 'object-storage':
    order           => '130',
    public          => true,
    public_ssl      => $public_ssl,
    public_ssl_path => $public_ssl_path,
  }

  if $baremetal_virtual_ip {
    openstack::ha::haproxy_service { 'object-storage-baremetal':
      order               => '135',
      public_virtual_ip   => false,
      internal_virtual_ip => $baremetal_virtual_ip,
    }
  }
}
