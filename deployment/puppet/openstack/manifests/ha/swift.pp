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
# [*amqp_names*]
#   (required) Array. This is an array of AMQP server names for
#   the swift-rabbitmq haproxy service, when ceilo is enabled
#
# [*amqp_ipaddresses*]
#   (required) Array. This is an array of server names for
#   the swift-rabbitmq haproxy service, when ceilo is enabled
#
# [*amqp_swift_proxy_enabled*]
#   (optional) Boolean. If true, enables  swift-rabbitmq haproxy service
#   Defaults to false
#
class openstack::ha::swift (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $amqp_ipaddresses,
  $amqp_names,
  $public_ssl = false,
  $baremetal_virtual_ip = undef,
  $amqp_swift_proxy_enabled = false,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    listen_port            => 8080,
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    haproxy_config_options => {
      'option'       => ['httpchk', 'httplog', 'httpclose'],
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
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
      public_virtual_ip      => false,
      internal_virtual_ip    => $baremetal_virtual_ip,
    }
  }

  if $amqp_swift_proxy_enabled {
    openstack::ha::haproxy_service { 'swift_proxy_rabbitmq':
      order                  => '121',
      listen_port            => 5673,
      define_backups         => true,
      internal               => true,
      ipaddresses            => $amqp_ipaddresses,
      server_names           => $amqp_names,
      haproxy_config_options => {
        'option'         => ['tcpka'],
        'timeout client' => '48h',
        'timeout server' => '48h',
        'balance'        => 'roundrobin',
        'mode'           => 'tcp'
      },
      balancermember_options => 'check inter 5000 rise 2 fall 3',
    }
  }
}
