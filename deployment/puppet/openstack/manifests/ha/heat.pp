# HA configuration for OpenStack Nova
class openstack::ha::heat (
    $ssl_certificate = undef,
) {

  openstack::ha::haproxy_service { 'heat-api':
    order           => '160',
    listen_port     => 8004,
    public          => true,
    require_service => 'heat-api',
    ssl_certificate => $ssl_certificate,
  }

  openstack::ha::haproxy_service { 'heat-api-cfn':
    order           => '161',
    listen_port     => 8003,
    public          => true,
    require_service => 'heat-api',
  }

  openstack::ha::haproxy_service { 'heat-api-cloudwatch':
    order           => '162',
    listen_port     => 8000,
    public          => true,
    require_service => 'heat-api',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['heat-api']
  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['heat-api-cfn']
  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['heat-api-cloudwatch']
}
