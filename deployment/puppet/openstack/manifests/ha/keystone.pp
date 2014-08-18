# HA configuration for OpenStack Keystone
class openstack::ha::keystone (
    $ssl_certificate = undef,
) {

  openstack::ha::haproxy_service { 'keystone-1':
    order           => '020',
    listen_port     => 5000,
    public          => true,
    ssl_certificate => $ssl_certificate,
  }

  openstack::ha::haproxy_service { 'keystone-2':
    order           => '030',
    listen_port     => 35357,
    public          => true,
    ssl_certificate => $ssl_certificate,
  }
  Openstack::Ha::Haproxy_service['keystone-1', 'keystone-2']->Service<| title=='keystone' |>
}
