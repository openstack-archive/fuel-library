# Configuration for Haproxy Stats page
class openstack::ha::stats ( ) {
  openstack::ha::haproxy_service { 'stats':
    order          => '010',
    listen_port    => '10000',
    haproxy_config_options => {
      'stats' => ['enable', 'uri /', 'refresh 5s', 'show-node', 'show-legends', 'hide-version'],
      'mode'  => 'http',
    },
  }
}

