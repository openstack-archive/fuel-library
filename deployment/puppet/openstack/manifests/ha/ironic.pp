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
class openstack::ha::ironic (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl = false,
  $baremetal_virtual_ip,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public                 => true,
    haproxy_config_options => {
        option => ['httpchk GET /', 'httplog','httpclose'],
    },
  }

  openstack::ha::haproxy_service { 'ironic-baremetal':
    order               => '185',
    listen_port         => 6385,
    internal            => true,
    public              => false,
    internal_virtual_ip => $baremetal_virtual_ip,
  }

  openstack::ha::haproxy_service { 'ironic-api':
    order               => '180',
    listen_port         => 6385,
    public              => true,
    public_ssl          => $public_ssl,
    internal_virtual_ip => $internal_virtual_ip,
  }
}
