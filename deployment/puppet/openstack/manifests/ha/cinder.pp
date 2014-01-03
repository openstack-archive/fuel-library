# HA configuration for OpenStack Nova
class openstack::ha::cinder {

  openstack::ha::haproxy_service { 'cinder-api':
    order           => '070',
    listen_port     => 8776,
    public          => true,
    require_service => 'cinder-api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['cinder-api']
}
