# HA configuration for OpenStack Nova
class openstack::ha::nova (
  $server_names,
  $ipaddresses,
  $public_ssl = false,
) {

  openstack::ha::haproxy_service { 'nova-api-1':
    order                  => '040',
    listen_port            => 8773,
    public                 => true,
    public_ssl             => $public_ssl,
    require_service        => 'nova-api',
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
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
    require_service        => 'nova-api',
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
