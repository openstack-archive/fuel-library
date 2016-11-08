# == Class: openstack::ha::horizon
#
# HA configuration for OpenStack Horizon
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
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
# [*use_ssl*]
#   (optional) Boolean. This flag indicates if we should also configure the ssl
#   port for the horizon vip
#   Defaults to false
#
# [*public_ssl_path*]
#   (optional) String. Filesystem path to the file with certificate content
#   Defaults to undef
#
class openstack::ha::horizon (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $use_ssl = false,
  $public_ssl_path = undef,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public              => true,
    internal            => false,
  }

  if $use_ssl {
    # http version of horizon should just redirect to https version
    openstack::ha::haproxy_service { 'horizon':
      order                  => '015',
      listen_port            => 80,
      server_names           => undef,
      ipaddresses            => undef,
      haproxy_config_options => {
        'option'   => 'http-buffer-request',
        'timeout'  => 'http-request 10s',
        'redirect' => 'scheme https if !{ ssl_fc }'
      },
    }

    openstack::ha::haproxy_service { 'horizon-ssl':
      order                  => '017',
      listen_port            => 443,
      balancermember_port    => 80,
      public_ssl             => $use_ssl,
      public_ssl_path        => $public_ssl_path,
      haproxy_config_options => {
        'option'      => ['forwardfor', 'httpchk', 'forceclose', 'httplog', 'http-buffer-request'],
        'timeout'     => ['client 3h', 'server 3h', 'http-request 10s'],
        'stick-table' => 'type ip size 200k expire 30m',
        'stick'       => 'on src',
        'balance'     => 'source',
        'mode'        => 'http',
        'reqadd'      => 'X-Forwarded-Proto:\ https',
      },
      balancermember_options => 'weight 1 check',
    }
  } else {
    # http only
    openstack::ha::haproxy_service { 'horizon':
      order                  => '015',
      listen_port            => 80,
      define_cookies         => true,
      haproxy_config_options => {
        'option'  => ['forwardfor', 'httpchk', 'forceclose', 'httplog', 'http-buffer-request'],
        'timeout' => ['client 3h', 'server 3h', 'http-request 10s'],
        'rspidel' => '^Set-cookie:\ IP=',
        'balance' => 'source',
        'mode'    => 'http',
        'cookie'  => 'SERVERID insert indirect nocache',
        'capture' => 'cookie vgnvisitor= len 32',
      },
      balancermember_options => 'check inter 2000 fall 3',
    }
  }
}
