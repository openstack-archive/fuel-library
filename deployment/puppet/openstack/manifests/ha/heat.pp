# == Class: openstack::ha::heat
#
# HA configuration for OpenStack Heat
#
# === Paramters
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
class openstack::ha::heat (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public                 => true,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'heat-api':
    order       => '160',
    listen_port => 8004,
  }

  openstack::ha::haproxy_service { 'heat-api-cfn':
    order       => '161',
    listen_port => 8000,
  }

  openstack::ha::haproxy_service { 'heat-api-cloudwatch':
    order       => '162',
    listen_port => 8003,
  }
}
