# HA configuration for RabbitMQ for OpenStack
class openstack::ha::murano_rabbitmq {

  openstack::ha::haproxy_service { 'murano_rabbitmq':
    order               => '190',
    listen_port         => 55572,
    define_backups      => true,
    before_start        => true,

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
