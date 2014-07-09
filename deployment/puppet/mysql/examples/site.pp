$master_hostname          = 'node-1'
$primary_controller = $::hostname ? {
  $master_hostname => true,
  default          => false,
}
$galera_node_addresses    = ['node-1', 'node-2']
$galera_cluster_name      = 'openstack'
$galera_master_ip         = 'master_ip'
$custom_mysql_setup_class = 'galera'
$mysql_root_password      = 'nova'
$enabled                  = true

node /node-[\d+]/ {
  class { 'mysql::server':
    config_hash         => {
      'bind_address' => '0.0.0.0'
    }
    ,
    galera_cluster_name => $galera_cluster_name,
    primary_controller  => $primary_controller,
    galera_node_address => $::hostname,
    enabled             => $enabled,
    custom_setup_class  => $custom_mysql_setup_class,
  }
}
