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
#   (required) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
#
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip.
#
# [*public_ssl*]
#   (optional) Boolean. If true, enables SSL for $public_virtual_ip
#   Defaults to false.
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
class openstack::ha::heat (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $public_ssl = false,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public                 => true,
    public_ssl             => $public_ssl,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option           => ['httpchk', 'httplog', 'httpclose'],
        'timeout server' => '660s',
        'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'heat-api':
    order                  => '160',
    listen_port            => 8004,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option           => ['httpchk', 'httplog', 'httpclose'],
        'timeout server' => '660s',
        'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
  }

  openstack::ha::haproxy_service { 'heat-api-cfn':
    order                  => '161',
    listen_port            => 8000,
    require_service        => 'heat-api',
  }

  openstack::ha::haproxy_service { 'heat-api-cloudwatch':
    order                  => '162',
    listen_port            => 8003,
    require_service        => 'heat-api',
  }
}
