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
class openstack::ha::swift (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl = false,
  $baremetal_virtual_ip = undef,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    listen_port         => 8080,
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    haproxy_config_options => {
      'option' => ['httpchk', 'httplog', 'httpclose'],
    },
    balancermember_options => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'swift':
    order                  => '120',
    public                 => true,
    public_ssl             => $public_ssl,
  }

  if $baremetal_virtual_ip {
    openstack::ha::haproxy_service { 'swift-baremetal':
      order                  => '125',
      public                 => false,
      public_ssl             => false,
      public_virtual_ip      => false,
      internal_virtual_ip    => $baremetal_virtual_ip,
    }
  }
}
