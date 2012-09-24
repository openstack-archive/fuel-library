$master_hostname = 'fuel-01'
$which = $::hostname ? { $master_hostname => 0, default => 1 }
$galera_cluster_name = 'openstack'
$galera_master_ip = 'master_ip'
$galera_node_address => $controller_internal_addresses[$which]
$custom_mysql_setup_class = 'galera'
$mysql_root_password = 'nova'

class { "mysql::server":
    config_hash => {
      # 'root_password' => $mysql_root_password,
      'bind_address'  => '0.0.0.0'
    },
    galera_cluster_name	=> $galera_cluster_name,
    galera_master_ip	=> $galera_master_ip,
    galera_node_address	=> $galera_node_address,
    enabled => $enabled,
    custom_setup_class => $custom_mysql_setup_class,
  }