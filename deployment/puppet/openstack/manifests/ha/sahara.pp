# HA configuration for OpenStack Sahara
class openstack::ha::sahara (
  $server_names,
  $ipaddresses,
  $public_ssl = false,
) {

  openstack::ha::haproxy_service { 'sahara':
    order           => '150',
    listen_port     => 8386,
    public          => true,
    public_ssl      => $public_ssl,
    require_service => 'sahara-api',
    server_names    => $server_names,
    ipaddresses     => $ipaddresses,
  }
}
