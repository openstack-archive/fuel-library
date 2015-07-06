notice('MODULAR: database.pp')

$internal_address         = hiera('internal_address')
$management_network_range = hiera('management_network_range')
$controller_nodes         = hiera('controller_nodes')
$use_syslog               = hiera('use_syslog', true)
$primary_controller       = hiera('primary_controller')
$mysql_hash               = hiera_hash('mysql', {})

$mysql_database_password  = $mysql_hash['root_password']
$mysql_database_enabled   = pick($mysql_hash['enabled'], true)

$mysql_bind_address       = '0.0.0.0'

$galera_cluster_name      = 'openstack'
$mysql_skip_name_resolve  = true
$custom_setup_class       = pick($mysql_hash['custom_setup_class'], 'galera')

$status_user              = hiera('galera_cluster_name', 'openstack')
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
    primary_controller      => $primary_controller,
    galera_node_address     => $internal_address,
    galera_nodes            => $controller_nodes,
    enabled                 => $mysql_database_enabled,
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

  class { 'openstack::galera::status':
    status_user     => $status_user,
    status_password => $status_password,
    status_allow    => $internal_address,
    backend_host    => $internal_address,
    backend_port    => $backend_port,
    backend_timeout => $backend_timeout,
    only_from       => "127.0.0.1 240.0.0.2 ${management_network_range}",
  }

  class { 'osnailyfacter::mysql_access':
    db_password => $mysql_database_password,
  }

  Package['socat'] ->
    Class['mysql::server'] ->
      Class['osnailyfacter::mysql_root'] ->
        Exec['initial_access_config'] ->
          Class['openstack::galera::status'] ->
            Class['osnailyfacter::mysql_access']

}
