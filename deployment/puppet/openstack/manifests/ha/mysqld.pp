# HA configuration for MySQL/Galera for OpenStack
class openstack::ha::mysqld (
  $is_primary_controller = false,
  $before_start = false
){

  openstack::ha::haproxy_service { 'mysqld':
    order               => '110',
    listen_port         => 3306,
    balancermember_port => 3307,
    define_backups      => true,
    before_start        => $before_start,

    haproxy_config_options => {
      'option'         => ['httpchk', 'tcplog','clitcpka','srvtcpka'],
      'balance'        => 'leastconn',
      'mode'           => 'tcp',
      'timeout server' => '28801s',
      'timeout client' => '28801s'
    },

    balancermember_options => 'check port 49000 inter 15s fastinter 2s downinter 1s rise 3 fall 3',
  }
}
