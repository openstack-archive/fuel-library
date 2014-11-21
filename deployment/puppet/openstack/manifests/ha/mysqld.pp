# HA configuration for MySQL/Galera for OpenStack
class openstack::ha::mysqld (
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

  package { 'socat' :
    ensure => 'installed',
  }

  haproxy_backend_status { 'mysql' :
    name => 'mysqld',
    url  => "http://${::fuel_settings['management_vip']}:10000/;csv",
  }

  Class['cluster::haproxy_ocf'] -> Haproxy_backend_status['mysql']
  Exec<| title == 'wait-for-synced-state' |> -> Haproxy_backend_status['mysql']
  Openstack::Ha::Haproxy_service<| title == 'mysqld' |> -> Haproxy_backend_status['mysql']
  Haproxy_backend_status['mysql'] -> Exec<| title == 'keystone-manage db_sync' |>
  Haproxy_backend_status['mysql'] -> Exec<| title == 'glance-manage db_sync' |>
  Haproxy_backend_status['mysql'] -> Exec<| title == 'cinder-manage db_sync' |>
  Haproxy_backend_status['mysql'] -> Exec<| title == 'nova-db-sync' |>
  Haproxy_backend_status['mysql'] -> Exec<| title == 'heat-dbsync' |>
  Haproxy_backend_status['mysql'] -> Exec<| title == 'ceilometer-dbsync' |>
  Haproxy_backend_status['mysql'] -> Exec<| title == 'neutron-db-sync' |>
  Haproxy_backend_status['mysql'] -> Service <| title == 'cinder-scheduler' |>
  Haproxy_backend_status['mysql'] -> Service <| title == 'cinder-volume' |>
  Haproxy_backend_status['mysql'] -> Service <| title == 'cinder-api' |>

}
