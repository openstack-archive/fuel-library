# HA configuration for OpenStack Ceilometer
class openstack::ha::ceilometer (
  $server_names,
  $ipaddresses,
) {

  openstack::ha::haproxy_service { 'ceilometer':
    order           => '140',
    listen_port     => 8777,
    public          => true,
    require_service => 'ceilometer-api',
    server_names    => $server_names,
    ipaddresses     => $ipaddresses,
  }
}
