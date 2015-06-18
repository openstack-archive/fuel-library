# HA configuration for OpenStack Sahara
class openstack::ha::sahara (
  $server_names,
  $ipaddresses,
) {

  openstack::ha::haproxy_service { 'sahara':
    order           => '150',
    listen_port     => 8386,
    public          => true,
    require_service => 'sahara-api',
    server_names    => $server_names,
    ipaddresses     => $ipaddresses,
  }
}
