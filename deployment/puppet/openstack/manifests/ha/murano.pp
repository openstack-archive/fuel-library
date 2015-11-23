# == Class: openstack::ha::murano
#
# HA configuration for OpenStack Murano
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
class openstack::ha::murano (
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
    public              => true,
  }

  openstack::ha::haproxy_service { 'murano-api':
    order                  => '180',
    listen_port            => 8082,
    public_ssl             => $public_ssl,
    require_service        => 'murano_api',
    haproxy_config_options => {
      'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
  }

  openstack::ha::haproxy_service { 'murano_rabbitmq':
    order                  => '190',
    listen_port            => 55572,
    define_backups         => true,
    internal               => false,
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
