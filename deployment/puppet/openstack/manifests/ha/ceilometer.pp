# HA configuration for OpenStack Ceilometer
class openstack::ha::ceilometer (
  $public_ssl = false,
) {

  openstack::ha::haproxy_service { 'ceilometer':
    order           => '140',
    listen_port     => 8777,
    public          => true,
    public_ssl      => $public_ssl,
    require_service => 'ceilometer-api',
  }
}
