# == Class: openstack::ha::nova
#
# HA configuration for OpenStack Nova
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
class openstack::ha::nova (
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

  openstack::ha::haproxy_service { 'nova-api-1':
    order                  => '040',
    listen_port            => 8773,
    public                 => true,
    public_ssl             => $public_ssl,
    require_service        => 'nova-api',
    haproxy_config_options => {
      'timeout server' => '600s',
    },
  }

  openstack::ha::haproxy_service { 'nova-api-2':
    order                  => '050',
    listen_port            => 8774,
    public                 => true,
    public_ssl             => $public_ssl,
    require_service        => 'nova-api',
    haproxy_config_options => {
      option           => ['httpchk', 'httplog', 'httpclose'],
      'timeout server' => '600s',
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'nova-metadata-api':
    order                  => '060',
    listen_port            => 8775,
    haproxy_config_options => {
      option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'nova-novncproxy':
    order           => '170',
    listen_port     => 6080,
    public          => true,
    public_ssl      => $public_ssl,
    internal        => false,
    require_service => 'nova-vncproxy',
  }
}
