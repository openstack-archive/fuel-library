# Class: mysql::server
#
# manages the installation of the mysql server.  manages the package, service,
# my.cnf
#
# Parameters:
#   [*package_name*] - name of package
#   [*service_name*] - name of service
#   [*config_hash*]  - hash of config parameters that need to be set.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::server (
  $custom_setup_class = undef,
  $package_name     = $mysql::params::server_package_name,
  $package_ensure   = 'present',
  $service_name     = $mysql::params::service_name,
  $service_provider = $mysql::params::service_provider,
  $config_hash      = {},
  $enabled          = true,
  $galera_cluster_name = undef,
  $galera_master_ip = undef,
  $galera_node_address = undef,
  $galera_nodes = undef
) inherits mysql::params {
  
  if ($custom_setup_class == undef) {
    Class['mysql::server'] -> Class['mysql::config']

    create_resources( 'class', { 'mysql::config' => $config_hash } )
    package { 'mysql-server':
      name   => $package_name,
      ensure => $package_ensure,
    }
 
    service { 'mysqld':
      name     => $service_name,
      ensure   => $enabled ? { true => 'running', default => 'stopped' },
      enable   => $enabled,
      require  => Package['mysql-server'],
      provider => $service_provider,
    }
  }
  elsif ($custom_setup_class == 'galera')  {
    Class['galera'] -> Class['mysql::server']
    class { 'galera':
	    cluster_name => $galera_cluster_name,
	    master_ip => $galera_master_ip,
	    node_address => $galera_node_address,
      node_addresses => $galera_nodes,
    }
#    require($galera_class)
  }
  
   else {
    require($custom_setup_class)
  }
}
