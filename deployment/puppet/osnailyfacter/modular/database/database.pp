notice('MODULAR: database.pp')

$neutron              = hiera('use_neutron')
$mysql_hash           = hiera_hash('mysql',{})
$keystone_hash        = hiera_hash('keystone',{})
$glance_hash          = hiera_hash('glance',{})
$nova_hash            = hiera_hash('nova',{})
$cinder_hash          = hiera_hash('cinder',{})
$neutron_config       = hiera_hash('quantum_settings')
$internal_address     = hiera('internal_address')
$network_scheme       = hiera('network_scheme', {})
$controller_nodes     = hiera('controller_nodes')
$database_nodes       = hiera('database_nodes',$controller_nodes)
$use_syslog           = hiera('use_syslog', true)
$primary_controller   = hiera('primary_controller')
$primary_database     = hiera('primary_database', $primary_controller)
$management_vip       = hiera('management_vip')
$database_vip         = hiera('database_vip',$management_vip)

$haproxy_stats_port   = hiera('haproxy_stats_port','10000')
$haproxy_stats_url    = hiera('haproxy_stats_url',"http://${database_vip}:${haproxy_stats_port}/;csv")

$mysql_root_password    = $mysql_hash['root_password']
$mysql_bind_address     = '0.0.0.0'
$mysql_account_security = true

$keystone_db_user       = pick($keystone_hash['db_user'], 'keystone')
$keystone_db_dbname     = pick($keystone_hash['db_name'], 'keystone')
$keystone_db_password   = $keystone_hash['db_password']

$glance_db_user         = pick($glance_hash['db_user'], 'glance')
$glance_db_dbname       = pick($glance_hash['db_name'], 'glance')
$glance_db_password     = $glance_hash['db_password']

$nova_db_user           = pick($nova_hash['db_user'], 'nova')
$nova_db_dbname         = pick($nova_hash['db_name'], 'nova')
$nova_db_password       = $nova_hash['db_password']

$cinder_db_user         = pick($cinder_hash['db_user'], 'nova')
$cinder_db_dbname       = pick($cinder_hash['db_name'], 'cinder')
$cinder_db_password     = $cinder_hash['db_password']

$neutron_db_user        = pick($neutron_config['database']['user'], 'neutron')
$neutron_db_dbname      = pick($neutron_config['database']['name'], 'neutron')
$neutron_db_password    = $neutron_config['database']['passwd']

$enabled                  = true
$allowed_hosts            = [ '%', $::hostname ]
$galera_cluster_name      = hiera('galera_cluster_name', 'openstack')
$galera_node_address      = $internal_address
$galera_nodes             = $database_nodes
$custom_mysql_setup_class = hiera('custom_mysql_setup_class','galera')
$mysql_skip_name_resolve  = true

$status_user              = 'clustercheck'
$status_password          = $mysql_hash['wsrep_password']
$backend_port             = '3307'
$backend_timeout          = '10'
$man_net                  = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

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
  primary_controller      => $primary_database,
  galera_node_address     => $galera_node_address,
  galera_nodes            => $galera_nodes,
  custom_setup_class      => $custom_mysql_setup_class,
  mysql_skip_name_resolve => $mysql_skip_name_resolve,
  use_syslog              => $use_syslog,
}

class { 'openstack::galera::status':
  status_user     => $status_user,
  status_password => $status_password,
  status_allow    => $galera_node_address,
  backend_host    => $galera_node_address,
  backend_port    => $backend_port,
  backend_timeout => $backend_timeout,
  only_from       => "127.0.0.1 240.0.0.2 ${man_net}",
}

haproxy_backend_status { 'mysql' :
  name => 'mysqld',
  url  => $haproxy_stats_url,
}

package { 'socat': ensure => present }

Package['socat'] -> Class['openstack::db::mysql']
Class['openstack::db::mysql'] -> Class['openstack::galera::status']
Class['openstack::galera::status'] -> Haproxy_backend_status['mysql']
Class['mysql::server'] -> Haproxy_backend_status['mysql']
