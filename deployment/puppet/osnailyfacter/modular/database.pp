
$deployment_mode      = hiera('deployment_mode')
$mysql_hash           = hiera('mysql_hash')
$primary_controller   = hiera('primary_controller')
$controller_nodes     = hiera('controller_nodes')
$controller_hostnames = hiera('controller_hostnames')


if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {

  package { 'socat': ensure => present }

  if $custom_mysql_setup_class {
    file { '/etc/mysql/my.cnf':
      ensure    => absent,
      require   => Class['mysql::server']
    }
    $config_hash_real = {
      'config_file' => '/etc/my.cnf'
    }
  } else {
    $config_hash_real = {}
  }

  class { "mysql::server" :
    bind_address            => '0.0.0.0',
    etc_root_password       => true,
    root_password           => $mysql_hash['root_password'],
    old_root_password       => '',
    galera_cluster_name     => 'openstack',
    primary_controller      => $primary_controller,
    galera_node_address     => hiera(internal_address),
    galera_nodes            => $controller_nodes,
    enabled                 => true,
    custom_setup_class      => 'galera',
    mysql_skip_name_resolve => true,
    use_syslog              => false,
    config_hash             => $config_hash_real,
    require                 => Package['socat'],
   }

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  cluster::haproxy_service { 'mysqld':
    server_names           => $controller_hostnames,
    ipaddresses            => $controller_nodes,
    public_virtual_ip      => hiera('public_vip'),
    internal_virtual_ip    => hiera('management_vip'),
    order                  => '110',
    listen_port            => 3306,
    balancermember_port    => 3307,
    define_backups         => true,
    haproxy_config_options => {
      'option'         => ['httpchk', 'tcplog','clitcpka','srvtcpka'],
      'balance'        => 'leastconn',
      'mode'           => 'tcp',
      'timeout server' => '28801s',
      'timeout client' => '28801s'
    },
    balancermember_options => 'check port 49000 inter 15s fastinter 2s downinter 1s rise 3 fall 3',
  }

  Class[ 'mysql::server' ] -> Cluster::Haproxy_service<| title == 'mysqld' |>

  } else {
     class { "mysql::server" :
       bind_address            => '0.0.0.0',
       etc_root_password       => true,
       root_password           => $mysql_hash['root_password'],
       old_root_password       => '',
       galera_cluster_name     => 'openstack',
       primary_controller      => false,
       galera_node_address     => '127.0.0.1',
       galera_nodes            => ['127.0.0.1'],
       enabled                 => true,
       custom_setup_class      => undef,
       mysql_skip_name_resolve => false,
       use_syslog              => false,
       config_hash             => {},
     }
  }
