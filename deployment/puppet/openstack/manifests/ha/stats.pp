# == Class: openstack::ha::stats
#
# Configuration for Haproxy Stats
#
# === Parameters
#
# [*internal_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the internal facing
#   vip
#
# [*ipaddresses*]
#   Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced. Not needed, because we do not use backend here.
#
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   Array. This is an array of server names for the haproxy service.
#   Not needed, because we do not use backend here.
#
class openstack::ha::stats ( $internal_virtual_ip,
                             $ipaddresses = '127.0.0.1',
                             $public_virtual_ip,
                             $server_names = 'localhost' ) {
  openstack::ha::haproxy_service { 'stats':
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    internal_virtual_ip    => $internal_virtual_ip,
    order                  => '010',
    listen_port            => '10000',
    haproxy_config_options => {
      'stats' => ['enable', 'uri /', 'refresh 5s', 'show-node', 'show-legends', 'hide-version'],
      'mode'  => 'http',
    },
  }
}

