# HA configuration for OpenStack Sahara
class openstack::ha::sahara {

  openstack::ha::haproxy_service { 'sahara':
    order           => '150',
    listen_port     => 8386,
    public          => true,
    require_service => 'sahara-api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['sahara-api']
}
