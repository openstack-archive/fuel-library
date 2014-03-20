# HA configuration for MySQL/Galera for OpenStack
class openstack::ha::mysqld (
  $is_primary_controller = false,
){

  openstack::ha::haproxy_service { 'mysqld':
    order               => '110',
    listen_port         => 3306,
    balancermember_port => 3307,
    define_backups      => true,
    #before_start        => true,

    haproxy_config_options => {
      'option'         => ['mysql-check user cluster_watcher', 'tcplog','clitcpka','srvtcpka'],
      'balance'        => 'roundrobin',
      'mode'           => 'tcp',
      'timeout server' => '28801s',
      'timeout client' => '28801s'
    },

    balancermember_options => 'check inter 15s fastinter 2s downinter 1s rise 5 fall 3',
  }

  package { 'socat': ensure => present }
  Package['socat'] -> Exec['wait-for-haproxy-mysql-backend']

  if $is_primary_controller {
    exec { 'wait-for-haproxy-mysql-backend':
      command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^mysqld,BACKEND,.*,UP,'",
      path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      try_sleep => 5,
      tries     => 60,
    }
  } else {
    exec { 'wait-for-haproxy-mysql-backend':
      command   => "true",
      path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      try_sleep => 5,
      tries     => 60,
    }
  }

  Class['cluster::haproxy_ocf'] -> Exec['wait-for-haproxy-mysql-backend']
  Exec<| title == 'wait-for-synced-state' |> -> Exec['wait-for-haproxy-mysql-backend']

  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'keystone-manage db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'glance-manage db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'cinder-manage db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'nova-db-sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'heat_db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'ceilometer-dbsync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-scheduler' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-volume' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-api' |>
}
