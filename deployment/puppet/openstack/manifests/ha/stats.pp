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
# [*public_virtual_ip*]
#   (optional) String. This is the ipaddress to be used for the external facing
#   vip
#
class openstack::ha::stats ($internal_virtual_ip,
                            $public_virtual_ip = undef) {
  openstack::ha::haproxy_service { 'stats':
    public_virtual_ip      => $public_virtual_ip,
    internal_virtual_ip    => $internal_virtual_ip,
    order                  => '010',
    listen_port            => '10000',
    haproxy_config_options => {
      'stats' => ['enable', 'uri /', 'refresh 5s', 'show-node',
                  'show-legends', 'hide-version'],
      'mode'  => 'http',
    },
  }
}
