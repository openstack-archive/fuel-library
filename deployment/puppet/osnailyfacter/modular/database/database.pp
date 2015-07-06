notice('MODULAR: database.pp')

$internal_address         = hiera('internal_address')
$management_network_range = hiera('management_network_range')
$controller_nodes         = hiera('controller_nodes')
$use_syslog               = hiera('use_syslog', true)
$primary_controller       = hiera('primary_controller')
$management_vip           = hiera('management_vip')
$database_vip             = hiera('database_vip', $management_vip)
$mysql_hash               = hiera_hash('mysql', {})

$haproxy_stats_port   = hiera('haproxy_stats_port','10000')
$haproxy_stats_url    = hiera('haproxy_stats_url',"http://${database_vip}:${haproxy_stats_port}/;csv")

$mysql_database_password  = $mysql_hash['root_password']
$mysql_database_enabled   = pick($mysql_hash['enabled'], true)
$mysql_db_host            = pick($database_vip, $management_vip, 'localhost')

$mysql_bind_address       = '0.0.0.0'

$galera_cluster_name      = 'openstack'
$galera_node_address      = $internal_address
$galera_nodes             = $controller_nodes
$mysql_skip_name_resolve  = true
$custom_setup_class       = pick($mysql_hash['custom_setup_class'], 'galera')
$haproxy_backend_status   = pick($mysql_hash['haproxy_backend_status'], true)

$status_user              = hiera('galera_cluster_name', 'openstack')
$status_password          = $mysql_hash['wsrep_password']
$backend_port             = '3307'
$backend_timeout          = '10'

#############################################################################
validate_string($status_password)
validate_string($mysql_database_password)
validate_string($database_vip)

if $mysql_database_enabled {

  if $custom_setup_class {
    file { '/etc/mysql/my.cnf':
      ensure  => absent,
      require => Class['mysql::server']
    }
    $config_hash_real = {
      'config_file' => '/etc/my.cnf'
    }
  } else {
    $config_hash_real = { }
  }

  class { 'mysql::server':
    bind_address            => '0.0.0.0',
    etc_root_password       => true,
    root_password           => $mysql_database_password,
    old_root_password       => '',
    galera_cluster_name     => $galera_cluster_name,
    primary_controller      => $primary_controller,
    galera_node_address     => $galera_node_address,
    galera_nodes            => $galera_nodes,
    enabled                 => $mysql_database_enabled,
    custom_setup_class      => $custom_setup_class,
    mysql_skip_name_resolve => $mysql_skip_name_resolve,
    use_syslog              => $use_syslog,
    config_hash             => $config_hash_real,
  }

  class { 'osnailyfacter::mysql_access':
    db_user     => 'root',
    db_password => $mysql_database_password,
    db_host     => $mysql_db_host,
  }

  class { 'osnailyfacter::mysql_root':
    password => $mysql_database_password,
  }

  exec { 'initial_access_config':
    command => '/bin/ln -sf /etc/mysql/conf.d/password.cnf /root/.my.cnf',
  }

  class { 'openstack::galera::status':
    status_user     => $status_user,
    status_password => $status_password,
    status_allow    => $galera_node_address,
    backend_host    => $galera_node_address,
    backend_port    => $backend_port,
    backend_timeout => $backend_timeout,
    only_from       => "127.0.0.1 240.0.0.2 ${management_network_range}",
  }

  if $haproxy_backend_status {
    haproxy_backend_status { 'mysql' :
      name => 'mysqld',
      url  => $haproxy_stats_url,
    }
    Exec['initial_access_config'] ->
      Class['openstack::galera::status'] ->
        Class['openstack::galera::status']
  }

  package { 'socat':
    ensure => 'present'
  }

  Package['socat'] ->
    Class['mysql::server'] ->
      Class['osnailyfacter::mysql_root'] ->
        Exec['initial_access_config'] ->
          Class['openstack::galera::status'] ->
              Class['osnailyfacter::mysql_access']

}
