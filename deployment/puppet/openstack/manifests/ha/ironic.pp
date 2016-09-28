# == Class: openstack::ha::ironic
#
# HA configuration for OpenStack Ironic
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
#   (optional) String. Path to public SSL certificate
#   Defaults to undef.
#
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*baremetal_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the baremetal facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
class openstack::ha::ironic (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $baremetal_virtual_ip,
  $public_ssl = false,
  $public_ssl_path = undef,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    listen_port            => 6385,
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    haproxy_config_options => {
      'option'       => ['httpchk GET /', 'httplog', 'forceclose', 'http-buffer-request'],
      'timeout'      => 'http-request 10s',
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
  }

  openstack::ha::haproxy_service { 'ironic':
    order           => '180',
    public          => true,
    public_ssl      => $public_ssl,
    public_ssl_path => $public_ssl_path,
  }

  openstack::ha::haproxy_service { 'ironic-baremetal':
    order               => '185',
    public_virtual_ip   => false,
    internal_virtual_ip => $baremetal_virtual_ip,
  }
}
