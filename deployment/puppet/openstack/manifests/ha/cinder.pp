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
class openstack::ha::cinder (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl = false,
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
    public_ssl             => $public_ssl,
    require_service        => 'cinder-api',
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    define_backups         => true,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
        http-request => 'set-header X-Forwarded-Proto https if { ssl_fc }',

    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
