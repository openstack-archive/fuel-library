# Configuration for Haproxy Stats page
class openstack::ha::stats ( $internal_virtual_ip,
                             $ipaddresses,
                             $public_virtual_ip,
                             $server_names ) {
  openstack::ha::haproxy_service { 'stats':
    server_names           => $server_names,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    internal_virtual_ip    => $internal_virtual_ip,
    order                  => '010',
    listen_port            => '10000',
    haproxy_config_options => {
      'stats' => ['enable', 'uri /', 'refresh 5s', 'show-node', 'show-legends', 'hide-version'],
      'mode'  => 'http',
    },
  }
}

