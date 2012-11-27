#
# This can be used to build out the simplest openstack controller
#
# === Parameters
#
# [public_interface] Public interface used to route public traffic. Required.
# [public_address] Public address for public endpoints. Required.
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [mysql_root_password] Root password for mysql server.
# [admin_email] Admin email.
# [admin_password] Admin password.
# [keystone_db_password] Keystone database password.
# [keystone_admin_token] Admin token for keystone.
# [glance_db_password] Glance DB password.
# [glance_user_password] Glance service user password.
# [nova_db_password] Nova DB password.
# [nova_user_password] Nova service password.
# [rabbit_password] Rabbit password.
# [rabbit_user] Rabbit User.
# [network_manager] Nova network manager to use.
# [fixed_range] Range of ipv4 network for vms.
# [floating_range] Floating ip range to create.
# [create_networks] Rather network and floating ips should be created.
# [num_networks] Number of networks that fixed range should be split into.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [verbose] Whether to log services at verbose.
# [export_resources] Rather to export resources.
# Horizon related config - assumes puppetlabs-horizon code
# [secret_key]          secret key to encode cookies, …
# [cache_server_ip]     local memcached instance ip
# [cache_server_port]   local memcached instance port
# [swift]               (bool) is swift installed
# [quantum]             (bool) is quantum installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# [enabled] Whether services should be enabled. This parameter can be used to
#   implement services in active-passive modes for HA. Optional. Defaults to true.
#
# === Examples
#
# class { 'openstack::controller':
#   public_address       => '192.168.0.3',
#   mysql_root_password  => 'changeme',
#   allowed_hosts        => ['127.0.0.%', '192.168.1.%'],
#   admin_email          => 'my_email@mw.com',
#   admin_password       => 'my_admin_password',
#   keystone_db_password => 'changeme',
#   keystone_admin_token => '12345',
#   glance_db_password   => 'changeme',
#   glance_user_password => 'changeme',
#   nova_db_password     => 'changeme',
#   nova_user_password   => 'changeme',
#   secret_key           => 'dummy_secret_key',
# }
#
class openstack::controller (
  # Required Network
  $public_address,
  $public_interface,
  $private_interface,
  # Required Database
  $mysql_root_password     = 'sql_pass',
  $custom_mysql_setup_class = undef,
  $admin_email             = 'some_user@some_fake_email_address.foo',
  $admin_password          = 'ChangeMe',
  $keystone_db_password    = 'keystone_pass',
  $keystone_admin_token    = 'keystone_admin_token',
  # Required Glance
  $glance_db_password      = 'glance_pass',
  $glance_user_password    = 'glance_pass',
  # Required Nova
  $nova_db_password        = 'nova_pass',
  $nova_user_password      = 'nova_pass',
  # Required Horizon
  $secret_key              = 'dummy_secret_key',
  # not sure if this works correctly
  $internal_address,
  $admin_address,
  # Rabbit
  $rabbit_password         = 'rabbit_pw',
  $rabbit_user             = 'nova',
  $rabbit_cluster          = false,
  $rabbit_nodes            = [$internal_address],
  # network configuration
  # this assumes that it is a flat network manager
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  # Database
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $mysql_bind_address      = '0.0.0.0',
  $allowed_hosts           = '%',
  # Keystone
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  # Glance
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  $glance_api_servers      = undef,
  # Nova
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = false,
  # Horizon
  $cache_server_ip         = ['127.0.0.1'],
  $cache_server_port       = '11211',
  $swift                   = false,
  $cinder                  = false,
  $horizon_app_links       = undef,
  # General
  $verbose                 = 'False',
  $export_resources        = true,
  # if the cinder management components should be installed
  $cinder_user_password    = 'cinder_user_pass',
  $cinder_db_password      = 'cinder_db_pass',
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  #
  $quantum                 = false,
  $quantum_user_password   = 'quantum_pass',
  $quantum_db_password     = 'quantum_pass',
  $quantum_db_user         = 'quantum',
  $quantum_db_dbname       = 'quantum',
  $enabled                 = true,
  $api_bind_address        = '0.0.0.0',
  $service_endpoint        = '127.0.0.1',
  $galera_cluster_name = 'openstack',
  $galera_master_ip = '127.0.0.1',
  $galera_node_address = '127.0.0.1',
  $glance_backend          = 'file',
  $galera_nodes = ['127.0.0.1'],
  $manage_volumes          = false,
  $nv_physical_volume      = undef,
) {

  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  Class['openstack::db::mysql'] -> Class['openstack::glance']
  Class['openstack::db::mysql'] -> Class['openstack::nova::controller']
  $rabbit_addresses = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
    $memcached_addresses =  inline_template("<%= @cache_server_ip.collect {|ip| ip + ':' + @cache_server_port }.join ',' %>")
 
  
  nova_config {'DEFAULT/memcached_servers':    value => $memcached_addresses;
  }


  include ntpd

  ####### DATABASE SETUP ######
  # set up mysql server
<<<<<<< HEAD
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
=======
  class { "mysql::server":
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # TODO I should make sure that this works
      # 'root_password' => $mysql_root_password,
      'bind_address'  => '0.0.0.0'
    },
    galera_cluster_name	=> $galera_cluster_name,
    galera_master_ip	=> $galera_master_ip,
    galera_node_address	=> $galera_node_address,
    galera_nodes        => $galera_nodes,
    enabled => $enabled,
    custom_setup_class => $custom_mysql_setup_class,
  }
  if ($enabled) {
    # set up all openstack databases, users, grants
    
    Class['keystone::config::mysql'] -> Exec<| title == 'keystone-manage db_sync' |>

    class { "keystone::db::mysql":
      host     => $mysql_host,
      password => $keystone_db_password,
      allowed_hosts => '%',
    }

    Class["glance::db::mysql"] -> Class['glance::registry']
    File['/etc/glance/glance-registry.conf'] -> Exec<| title == 'glance-manage db_sync' |>

    class { "glance::db::mysql":
      host     => $mysql_host,
      password => $glance_db_password,
      allowed_hosts => '%',
    }
    # TODO should I allow all hosts to connect?
    class { "nova::db::mysql":
      host          => $mysql_host,
      password      => $nova_db_password,
      allowed_hosts => '%',
>>>>>>> 94b9f1d... Fix [FUEL-198] for essex.
    }
    class { 'openstack::db::mysql':
      mysql_root_password    => $mysql_root_password,
      mysql_bind_address     => $mysql_bind_address,
      mysql_account_security => $mysql_account_security,
      keystone_db_user       => $keystone_db_user,
      keystone_db_password   => $keystone_db_password,
      keystone_db_dbname     => $keystone_db_dbname,
      glance_db_user         => $glance_db_user,
      glance_db_password     => $glance_db_password,
      glance_db_dbname       => $glance_db_dbname,
      nova_db_user           => $nova_db_user,
      nova_db_password       => $nova_db_password,
      nova_db_dbname         => $nova_db_dbname,
      cinder                 => $cinder,
      cinder_db_user         => $cinder_db_user,
      cinder_db_password     => $cinder_db_password,
      cinder_db_dbname       => $cinder_db_dbname,
      quantum                => $quantum,
      quantum_db_user        => $quantum_db_user,
      quantum_db_password    => $quantum_db_password,
      quantum_db_dbname      => $quantum_db_dbname,
      allowed_hosts          => $allowed_hosts,
      enabled                => $enabled,
     galera_cluster_name => $galera_cluster_name,
     galera_master_ip => $galera_master_ip ,
     galera_node_address => $galera_node_address ,
     custom_setup_class => $custom_mysql_setup_class,

   }
  }
  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose               => $verbose,
    db_type               => $db_type,
    db_host               => $db_host,
    db_password           => $keystone_db_password,
    db_name               => $keystone_db_dbname,
    db_user               => $keystone_db_user,
    admin_token           => $keystone_admin_token,
    admin_tenant          => $keystone_admin_tenant,
    admin_email           => $admin_email,
    admin_password        => $admin_password,
    public_address        => $public_address,
    internal_address      => $internal_address,
    admin_address         => $admin_address,
    glance_user_password  => $glance_user_password,
    nova_user_password    => $nova_user_password,
    cinder                => $cinder,
    cinder_user_password  => $cinder_user_password,
    quantum               => $quantum,
    bind_host    => $api_bind_address,
    quantum_user_password => $quantum_user_password,
    enabled               => $enabled,
    package_ensure => $::openstack_keystone_version,
  }


  ######## BEGIN GLANCE ##########
  class { 'openstack::glance':
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => $db_host,
    glance_db_user            => $glance_db_user,
    glance_db_dbname          => $glance_db_dbname,
    glance_db_password        => $glance_db_password,
    glance_user_password      => $glance_user_password,
    auth_uri          => "http://${service_endpoint}:5000/",
    keystone_host         => $service_endpoint,
    bind_host           => $api_bind_address,
    enabled                   => $enabled,
    glance_backend            => $glance_backend,
    registry_host     => $service_endpoint,
  }

  ######## BEGIN NOVA ###########
  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }
  if ($cinder) {
    $enabled_apis = 'ec2,osapi_compute,metadata'
  } else {
    $enabled_apis = 'ec2,osapi_compute,metadata,osapi_volume'
  }


  class { 'openstack::nova::controller':
    # Database
    db_host                 => $db_host,
    # Network
    network_manager         => $network_manager,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    public_address          => $public_address,
    admin_address           => $admin_address,
    internal_address        => $internal_address,
    private_interface       => $private_interface,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    create_networks         => $create_networks,
    num_networks            => $num_networks,
    multi_host              => $multi_host,
    keystone_host         => $service_endpoint,
    # Quantum
    quantum                 => $quantum,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    # Nova
    nova_user_password      => $nova_user_password,
    nova_db_password        => $nova_db_password,
    nova_db_user            => $nova_db_user,
    nova_db_dbname          => $nova_db_dbname,
    # Rabbit
    rabbit_user             => $rabbit_user,
    rabbit_password         => $rabbit_password,
    rabbit_nodes       => $rabbit_nodes,
    rabbit_cluster => $rabbit_cluster,
    # Glance
    glance_api_servers      => $glance_api_servers,
    # General
    verbose                 => $verbose,
    enabled                 => $enabled,
    exported_resources      => $export_resources,
    enabled_apis	=>	$enabled_apis,
    api_bind_address		=>	$api_bind_address,
    ensure_package    => $::openstack_version['nova']
  }

  ######### Cinder Controller Services ########
  if ($cinder) {
    class {'openstack::cinder':
      sql_connection => "mysql://${cinder_db_user}:${cinder_db_password}@${db_host}/${cinder_db_dbname}?charset=utf8",
      rabbit_password => $rabbit_password,
      rabbit_host     => false,
      rabbit_nodes    => $rabbit_nodes,
      volume_group    => 'cinder-volumes',
      physical_volume => $physical_volume,
      manage_volumes  => $manage_volumes,
      enabled         => true,
      auth_host       => $service_endpoint,
      bind_host       => $api_bind_address,
      cinder_user_password    => $cinder_user_password,
    }
 }


   else {
    if $manage_volumes {

    class { 'nova::volume':
      ensure_package => $::openstack_version['nova'],
      enabled        => true,
    }   

    class { 'nova::volume::iscsi':
      volume_group     => $nova_volume,
      iscsi_ip_address => $api_bind_address,
      physical_volume  => $nv_physical_volume,
    }   
  }


    # Set up nova-volume
  }

 if !defined(Class['memcached']){
  class { 'memcached':
    #    listen_ip => $api_bind_address,
  } 
 }


  ######## Horizon ########
  class { 'openstack::horizon':
    secret_key        => $secret_key,
    cache_server_ip   => $cache_server_ip,
    package_ensure => $::openstack_version['horizon'],
    bind_address => $api_bind_address,
    cache_server_port => $cache_server_port,
    swift             => $swift,
    quantum           => $quantum,
    horizon_app_links => $horizon_app_links,
    keystone_host => $service_endpoint,
  }

}
