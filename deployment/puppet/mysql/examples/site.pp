$master_hostname          = 'fuel-controller-01'
$primary_controller = $::hostname ? {
  $master_hostname => true,
  default          => false,
}
$galera_node_addresses    = ['fuel-controller-01', 'fuel-controller-02']
$galera_cluster_name      = 'openstack'
$galera_master_ip         = 'master_ip'
$custom_mysql_setup_class = 'galera'
$mysql_root_password      = 'nova'
$enabled                  = true

node /fuel-controller-[\d+]/ {
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
