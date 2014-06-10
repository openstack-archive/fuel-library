# HA configuration for OpenStack Murano
class openstack::ha::murano {

  openstack::ha::haproxy_service { 'murano':
    order           => '180',
    listen_port     => 8082,
    public          => true,
    require_service => 'murano_api',
  }

  openstack::ha::haproxy_service { 'murano_rabbitmq':
    order          => '190',
    listen_port    => 55572,
    define_backups => true,
    public         => true,
    internal       => false,

    haproxy_config_options => {
      'option'         => ['tcpka'],
      'timeout client' => '48h',
      'timeout server' => '48h',
      'balance'        => 'roundrobin',
      'mode'           => 'tcp'
    },

    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['murano_api']
}
