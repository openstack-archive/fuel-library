notice('MODULAR: database.pp')

$neutron              = hiera('use_neutron')
$mysql_hash           = hiera('mysql')
$keystone_hash        = hiera('keystone')
$glance_hash          = hiera('glance')
$nova_hash            = hiera('nova')
$cinder_hash          = hiera('cinder')
$internal_address     = hiera('internal_address')
$neutron_db_password  = hiera('neutron_db_password')
$controller_nodes     = hiera('controller_nodes')
$use_syslog           = hiera('use_syslog', true)
$primary_controller   = hiera('primary_controller')
$management_vip       = hiera('management_vip')

$haproxy_stats_port  = '10000'
$haproxy_stats_url   = "http://${management_vip}:${haproxy_stats_port}/;csv"

$mysql_root_password    = $mysql_hash['root_password']
$mysql_bind_address     = '0.0.0.0'
$mysql_account_security = true

$keystone_db_user       = 'keystone'
$keystone_db_dbname     = 'keystone'
$keystone_db_password   = $keystone_hash['db_password']

$glance_db_user         = 'glance'
$glance_db_dbname       = 'glance'
$glance_db_password     = $glance_hash['db_password']

$nova_db_user           = 'nova'
$nova_db_dbname         = 'nova'
$nova_db_password       = $nova_hash['db_password']

$cinder_db_user         = 'cinder'
$cinder_db_dbname       = 'cinder'
$cinder_db_password     = $cinder_hash['db_password']

$neutron_db_user        = 'neutron'
$neutron_db_dbname      = 'neutron'

$enabled                  = true
$allowed_hosts            = [ '%', $::hostname ]
$galera_cluster_name      = 'openstack'
$galera_node_address      = $internal_address
$galera_nodes             = $controller_nodes
$custom_mysql_setup_class = 'galera'
$mysql_skip_name_resolve  = true

$status_user              = 'clustercheck'
$status_password          = $mysql_hash['wsrep_password']
$backend_port             = '3307'
$backend_timeout          = '10'

###############################################################################

class { 'openstack::db::mysql':
  mysql_root_password     => $mysql_root_password,
  mysql_bind_address      => $mysql_bind_address,
  mysql_account_security  => $mysql_account_security,
  keystone_db_user        => $keystone_db_user,
  keystone_db_password    => $keystone_db_password,
  keystone_db_dbname      => $keystone_db_dbname,
  glance_db_user          => $glance_db_user,
  glance_db_password      => $glance_db_password,
  glance_db_dbname        => $glance_db_dbname,
  nova_db_user            => $nova_db_user,
  nova_db_password        => $nova_db_password,
  nova_db_dbname          => $nova_db_dbname,
  cinder                  => $cinder,
  cinder_db_user          => $cinder_db_user,
  cinder_db_password      => $cinder_db_password,
  cinder_db_dbname        => $cinder_db_dbname,
  neutron                 => $neutron,
  neutron_db_user         => $neutron_db_user,
  neutron_db_password     => $neutron_db_password,
  neutron_db_dbname       => $neutron_db_dbname,
  allowed_hosts           => $allowed_hosts,
  enabled                 => $enabled,
  galera_cluster_name     => $galera_cluster_name,
  primary_controller      => $primary_controller,
  galera_node_address     => $galera_node_address,
  galera_nodes            => $galera_nodes,
  custom_setup_class      => $custom_mysql_setup_class,
  mysql_skip_name_resolve => $mysql_skip_name_resolve,
  use_syslog              => $use_syslog,
}

class { 'openstack::galera::status':
  status_user             => $status_user,
  status_password         => $status_password,
  status_allow            => $galera_node_address,
  backend_host            => $galera_node_address,
  backend_port            => $backend_port,
  backend_timeout         => $backend_timeout,
}

haproxy_backend_status { 'mysql' :
  name    => 'mysqld',
  url     => $haproxy_stats_url,
}

Class['openstack::db::mysql'] -> Class['openstack::galera::status']
Class['openstack::galera::status'] -> Haproxy_backend_status['mysql']
Class['mysql::server'] -> Haproxy_backend_status['mysql']
