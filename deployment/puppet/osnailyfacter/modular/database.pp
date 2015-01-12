import 'globals.pp'

if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  #Have to move to globall.pp (todo)
  $primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')
  $primary_controller = $role ? { 'primary-controller'=>true, default=>false }
  $controllers = concat($primary_controller_nodes, filter_nodes($nodes_hash,'role','controller'))
  $controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
  $controller_nodes = ipsort(values($controller_internal_addresses))
  $galera_nodes = $controller_nodes
 
  package { 'socat': ensure => present }

  Service<| provider=='pacemaker' |> -> Class[ 'mysql::server' ]
  
  if $custom_mysql_setup_class {
    file { '/etc/mysql/my.cnf':
      ensure    => absent,
      require   => Class['mysql::server']
    }
    $config_hash_real = {
      'config_file' => '/etc/my.cnf'
    }
  } else {
    $config_hash_real = {}
  }
 
  class { "mysql::server" :
    bind_address            => '0.0.0.0',
    etc_root_password       => true,
    root_password           => $mysql_hash['root_password'],
    old_root_password       => '',
    galera_cluster_name     => 'openstack',
    primary_controller      => $primary_controller,
    galera_node_address     => $::internal_address,
    galera_nodes            => $galera_nodes,
    enabled                 => true,
    custom_setup_class      => 'galera',
    mysql_skip_name_resolve => true,
    use_syslog              => false,
    config_hash             => $config_hash_real,
    require   => Package['socat'],
   }

   } else {
     class { "mysql::server" :
       bind_address => '0.0.0.0',
       etc_root_password => true,
       root_password => $mysql_hash['root_password'],
       old_root_password => '',
       galera_cluster_name => 'openstack',
       primary_controller => false,
       galera_node_address => '127.0.0.1',
       galera_nodes => ['127.0.0.1'],
       enabled => true,
       custom_setup_class => undef,
       mysql_skip_name_resolve => false,
       use_syslog => false,
       config_hash => {},
     }
  }

