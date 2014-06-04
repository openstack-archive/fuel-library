# HA configuration for RabbitMQ for Murano
class openstack::ha::murano {

  openstack::ha::haproxy_service { 'murano-rabbitmq':
    order          => '100',
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
}
