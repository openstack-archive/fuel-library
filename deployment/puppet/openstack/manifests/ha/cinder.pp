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
#   (reqiured) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
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
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
