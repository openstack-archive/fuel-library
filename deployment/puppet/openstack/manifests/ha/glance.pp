# == Class: openstack::ha::glance
#
# HA configuration for OpenStack Glance
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
class openstack::ha::glance (
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

  openstack::ha::haproxy_service { 'glance-api':
    # before neutron
    order                  => '080',
    listen_port            => 9292,
    public                 => true,
    public_ssl             => $public_ssl,
    require_service        => 'glance-api',
    haproxy_config_options => {
        'option'         => ['httpchk /versions', 'httplog','httpclose'],
        'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        'timeout server' => '11m',
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'glance-registry':
    # after neutron
    order                  => '090',
    listen_port            => 9191,
    haproxy_config_options => {
      'timeout server' => '11m',
    },
  }
}
