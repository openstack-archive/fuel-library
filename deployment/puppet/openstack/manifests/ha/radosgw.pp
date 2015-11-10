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
  $public_ssl = false,
  $baremetal_virtual_ip = undef,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }

  openstack::ha::haproxy_service { 'radosgw':
    order                  => '130',
    listen_port            => 8080,
    balancermember_port    => 6780,
    public                 => true,
    public_ssl             => $public_ssl,
    haproxy_config_options => {
      'option' => ['httplog', 'httpchk GET /'],
    },
  }

  if $baremetal_virtual_ip {
    openstack::ha::haproxy_service { 'radosgw-baremetal':
      order                  => '135',
      public_virtual_ip      => false,
      internal_virtual_ip    => $baremetal_virtual_ip,
    }
  }
}
