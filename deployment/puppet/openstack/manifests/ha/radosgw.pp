# HA configuration for Ceph RADOS Gateway
class openstack::ha::radosgw (
  $balancers,
) {

  openstack::ha::haproxy_service { 'radosgw':
    order          => 97,
    port           => 8080,
    balancer_port  => 6780,
    balancers      => $balancers,
    public         => true,
    define_backend => true,
  }
}
