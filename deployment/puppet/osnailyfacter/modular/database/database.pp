notice('MODULAR: database.pp')

$internal_address         = hiera('internal_address')
$management_network_range = hiera('management_network_range')
$controller_nodes         = hiera('controller_nodes')
$use_syslog               = hiera('use_syslog', true)
$primary_controller       = hiera('primary_controller')
$mysql_hash               = hiera_hash('mysql', {})

$haproxy_stats_port   = '10000'
$haproxy_stats_url    = "http://${management_vip}:${haproxy_stats_port}/;csv"

$mysql_database_password   = $mysql_hash['root_password']
$mysql_database_enabled    = pick($mysql_hash['enabled'], true)


$galera_node_address       = $internal_address
$galera_nodes              = pick($mysql_hash['galera_nodes'],
                                  hiera_array('mysqld_ipaddresses', undef),
                                  $controller_nodes)
$galera_primary_controller = hiera('primary_database', $primary_controller)
$mysql_bind_address        = '0.0.0.0'

$galera_cluster_name      = 'openstack'
$mysql_skip_name_resolve  = true
$custom_setup_class       = hiera('mysql_custom_setup_class', 'galera')

# Get galera gcache factor based on cluster node's count
$galera_gcache_factor     = count(unique(filter_hash(hiera('nodes', []), 'uid')))

$status_user              = 'clustercheck'
$status_password          = $mysql_hash['wsrep_password']
$backend_port             = '3307'
$backend_timeout          = '10'

#############################################################################
validate_string($status_password)
validate_string($mysql_database_password)
validate_string($status_password)

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

  package { 'socat':
    ensure => 'present',
  }

  class { 'mysql::server':
    bind_address            => '0.0.0.0',
    etc_root_password       => true,
    root_password           => $mysql_database_password,
    old_root_password       => '',
    galera_cluster_name     => $galera_cluster_name,
    primary_controller      => $galera_primary_controller,
    galera_node_address     => $galera_node_address,
    galera_nodes            => $galera_nodes,
    galera_gcache_factor    => $galera_gcache_factor,
    enabled                 => $enabled,
    custom_setup_class      => $custom_setup_class,
    mysql_skip_name_resolve => $mysql_skip_name_resolve,
    use_syslog              => $use_syslog,
    config_hash             => $config_hash_real,
  }

  class { 'osnailyfacter::mysql_root':
    password => $mysql_database_password,
  }

  exec { 'initial_access_config':
    command => '/bin/ln -sf /etc/mysql/conf.d/password.cnf /root/.my.cnf',
  }

  if ($custom_mysql_setup_class == 'percona_packages' and $::osfamily == 'RedHat') {
    # This is a work around to prevent the conflict between the
    # MySQL-shared-wsrep package (included as a dependency for MySQL-python) and
    # the Percona shared package Percona-XtraDB-Cluster-shared-56. They both
    # provide the libmysql client libraries. Since we are requiring the
    # installation of the Percona package here before mysql::python, the python
    # client is happy and the server installation won't fail due to the
    # installation of our shared package
    package { 'Percona-XtraDB-Cluster-shared-56':
      ensure => 'present',
      before => Class['mysql::python'],
    }
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

  haproxy_backend_status { 'mysql' :
    name => 'mysqld',
    url  => $haproxy_stats_url,
  }

  class { 'osnailyfacter::mysql_access':
    db_password => $mysql_database_password,
  }

  Package['socat'] ->
    Class['mysql::server'] ->
      Class['osnailyfacter::mysql_root'] ->
        Exec['initial_access_config'] ->
          Class['openstack::galera::status'] ->
            Haproxy_backend_status['mysql'] ->
              Class['osnailyfacter::mysql_access']

}
