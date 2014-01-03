# HA configuration for OpenStack Swift
class openstack::ha::swift (
  $servers,
) {

  openstack::ha::haproxy_service { 'swift':
    order        => '120',
    listen_port  => 8080,
    server_names => filter_hash($servers, 'name'),
    ipaddresses  => filter_hash($servers, 'storage_address'),
    public       => true,
  }
}
