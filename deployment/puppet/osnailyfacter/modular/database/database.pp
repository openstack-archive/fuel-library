notice('MODULAR: database.pp')

$internal_address     = hiera('internal_address')
$network_scheme       = hiera('network_scheme', {})
$controller_nodes     = hiera('controller_nodes')
$use_syslog           = hiera('use_syslog', true)
$primary_controller   = hiera('primary_controller')
$management_vip       = hiera('management_vip')

$mysql_hash           = hiera_hash('mysql', {})

$haproxy_stats_port   = '10000'
$haproxy_stats_url    = "http://${management_vip}:${haproxy_stats_port}/;csv"

$mysql_database_user      = structure($mysql_hash, 'db_user', 'root')
$mysql_database_password  = structure($mysql_hash, 'root_password')
$mysql_database_host      = structure($mysql_hash, 'db_host', undef)

$mysql_bind_address       = '0.0.0.0'
$mysql_account_security   = true

$enabled                  = true
$allowed_hosts            = [ '%', $::hostname ]
$galera_cluster_name      = 'openstack'
$galera_node_address      = $internal_address
$galera_nodes             = $controller_nodes
$mysql_skip_name_resolve  = true
$custom_setup_class       = 'galera'

$status_user              = 'clustercheck'
$status_password          = structure($mysql_hash, 'wsrep_password')
$backend_port             = '3307'
$backend_timeout          = '10'

$management_interface     = structure($network_scheme, 'roles/management')
$management_network       = structure($network_scheme, "endpoints/${management_interface}/IP")

#############################################################################

if $mysql_database_host {

  # working with remote pre-installed database
  file { 'mysql_access_file' :
    path    => '/root/.my.cnf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('osnailyfacter/mysql.access.cnf.erb'),
  }

} else {

  if $custom_setup_class {
    file { '/etc/mysql/my.cnf':
      ensure    => absent,
      require   => Class['mysql::server']
    }
    $config_hash_real = {
      'config_file' => '/etc/my.cnf'
    }
  } else {
    $config_hash_real = { }
  }

  class { "mysql::server":
    bind_address            => '0.0.0.0',
    etc_root_password       => true,
    root_password           => $mysql_database_password,
    old_root_password       => '',
    galera_cluster_name     => $galera_cluster_name,
    primary_controller      => $primary_controller,
    galera_node_address     => $galera_node_address,
    galera_nodes            => $galera_nodes,
    enabled                 => $enabled,
    custom_setup_class      => $custom_setup_class,
    mysql_skip_name_resolve => $mysql_skip_name_resolve,
    use_syslog              => $use_syslog,
    config_hash             => $config_hash_real,
  }

# This removes default users and guest access
  if $mysql_account_security and $custom_setup_class == undef {
    class { 'mysql::server::account_security': }
  }

  class { 'openstack::galera::status':
    status_user     => $status_user,
    status_password => $status_password,
    status_allow    => $galera_node_address,
    backend_host    => $galera_node_address,
    backend_port    => $backend_port,
    backend_timeout => $backend_timeout,
    only_from       => "127.0.0.1 240.0.0.2 ${management_network}",
  }

  haproxy_backend_status { 'mysql' :
    name => 'mysqld',
    url  => $haproxy_stats_url,
  }

  package { 'socat': ensure => present }

  Package['socat'] ->
  Class['mysql::server'] ->
  Haproxy_backend_status['mysql']
  Class['mysql::server'] ->
  Class['openstack::galera::status'] ->
  Haproxy_backend_status['mysql']
}
