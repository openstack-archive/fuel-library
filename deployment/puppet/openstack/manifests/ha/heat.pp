# HA configuration for OpenStack Nova
class openstack::ha::heat (
  $server_names,
  $ipaddresses,
  $public_ssl = false,
  $internal_ssl => false,
) {

  openstack::ha::haproxy_service { 'heat-api':
    order                  => '160',
    listen_port            => 8004,
    public                 => true,
    public_ssl             => $public_ssl,
    internal_ssl           => $internal_ssl,
    require_service        => 'heat-api',
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'heat-api-cfn':
    order                  => '161',
    listen_port            => 8000,
    public                 => true,
    public_ssl             => $public_ssl,
    internal_ssl           => $internal_ssl,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'heat-api-cloudwatch':
    order                  => '162',
    listen_port            => 8003,
    public                 => true,
    public_ssl             => $public_ssl,
    internal_ssl           => $internal_ssl,
    require_service        => 'heat-api',
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }
}
