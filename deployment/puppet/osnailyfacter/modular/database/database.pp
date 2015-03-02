$mysql_hash           = hiera('mysql_hash')
$primary_controller   = hiera('primary_controller', false)
$internal_address     = hiera('internal_address')
$controller_nodes     = hiera('controller_nodes', false)
$controller_hostnames = hiera('controller_hostnames', false)
$use_syslog           = hiera('use_syslog', true)
$management_vip       = hiera('management_vip')

##################################################################

$galera_cluster_name = 'openstack'
$custom_setup_class  = 'galera'
$root_password       = $mysql_hash['root_password']
$haproxy_stats_port  = '10000'
$haproxy_stats_url   = "http://${management_vip}:${haproxy_stats_port}/;csv"

$config_hash = {
  'config_file' => '/etc/my.cnf'
}

file { '/etc/mysql/my.cnf':
  ensure    => absent,
}

class { 'mysql::server' :
  bind_address            => '0.0.0.0',
  etc_root_password       => true,
  root_password           => $root_password,
  old_root_password       => '',
  galera_cluster_name     => $galera_cluster_name,
  primary_controller      => $primary_controller,
  galera_node_address     => $internal_address,
  galera_nodes            => $controller_nodes,
  enabled                 => true,
  custom_setup_class      => $custom_setup_class,
  mysql_skip_name_resolve => true,
  use_syslog              => $use_syslog,
  config_hash             => $config_hash,
 }

if $primary_controller {
  haproxy_backend_status { 'mysqld' :
    name    => 'mysqld',
    url     => $haproxy_stats_url,
  }
}

Class['mysql::server'] -> File['/etc/mysql/my.cnf']
Class['mysql::server'] -> Haproxy_backend_status['mysqld']
