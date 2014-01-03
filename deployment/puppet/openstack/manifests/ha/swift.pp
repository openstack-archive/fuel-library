# HA configuration for OpenStack Swift
class openstack::ha::swift (
  $balancers,
) {

  openstack::ha::haproxy_service { 'swift':
    order     => 96,
    port      => 8080,
    balancers => $balancers,
    public    => true,
  }
}
