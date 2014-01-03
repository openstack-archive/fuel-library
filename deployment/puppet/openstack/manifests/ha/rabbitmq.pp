# HA configuration for RabbitMQ for OpenStack
class openstack::ha::rabbitmq {

  openstack::ha::haproxy_service { 'rabbitmq':
    order               => '100',
    listen_port         => 5672,
    balancermember_port => 5673,
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
