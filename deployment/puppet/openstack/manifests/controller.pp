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
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option 
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for main syslog files (/var/log/{messages, syslog, kern.log}). Optional.
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
  $custom_mysql_setup_class= undef,
  $admin_email             = 'some_user@some_fake_email_address.foo',
  $admin_user              = 'admin',
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
  $rabbit_node_ip_address  = undef,
  $rabbit_ha_virtual_ip    = false, #Internal virtual IP for HA configuration
  $rabbit_port             = '5672',
  # network configuration
  # this assumes that it is a flat network manager
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $network_size            = 255,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  # Database
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $mysql_bind_address      = '0.0.0.0',
  $allowed_hosts           = [ '%', $::hostname ],
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
  $cinder                  = true,
  $horizon_app_links       = undef,
  # General
  $verbose                 = 'False',
  $export_resources        = true,
  # if the cinder management components should be installed
  $cinder_user_password    = 'cinder_user_pass',
  $cinder_db_password      = 'cinder_db_pass',
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  $cinder_iscsi_bind_addr  = false,
  $cinder_volume_group     = 'cinder-volumes',
  #
  $quantum                 = false,
  $quantum_user_password   = 'quantum_pass',
  $quantum_db_password     = 'quantum_pass',
  $quantum_db_user         = 'quantum',
  $quantum_db_dbname       = 'quantum',
  $quantum_network_node    = false,
  $quantum_netnode_on_cnt  = false,
  $quantum_gre_bind_addr   = undef,
  $quantum_external_ipinfo = {},
  $segment_range           = '1:4094',
  $tenant_network_type     = 'gre',
  $enabled                 = true,
  $api_bind_address        = '0.0.0.0',
  $service_endpoint        = '127.0.0.1',
  $galera_cluster_name     = 'openstack',
  $primary_controller      = primary_controller,
  $galera_node_address     = '127.0.0.1',
  $glance_backend          = 'file',
  $galera_nodes            = ['127.0.0.1'],
  $mysql_skip_name_resolve = false,
  $manage_volumes          = false,
  $nv_physical_volume      = undef,
  $use_syslog              = false,
  $syslog_log_level        = 'INFO',
  $syslog_log_facility_glance   = 'LOCAL2',
  $syslog_log_facility_cinder   = 'LOCAL3',
  $syslog_log_facility_quantum  = 'LOCAL4',
  $syslog_log_facility_nova     = 'LOCAL6',
  $syslog_log_facility_keystone = 'LOCAL7',
  $horizon_use_ssl         = false,
  $nova_rate_limits        = undef,
  $cinder_rate_limits      = undef,
  $ha_mode                 = false,
) {


  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  Class['openstack::db::mysql'] -> Class['openstack::glance']
  Class['openstack::db::mysql'] -> Class['openstack::nova::controller']
  if defined(Class['openstack::cinder']) {
        Class['openstack::db::mysql'] -> Class['openstack::cinder']
  }

  $rabbit_addresses = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
    $memcached_addresses =  inline_template("<%= @cache_server_ip.collect {|ip| ip + ':' + @cache_server_port }.join ',' %>")
 
  
  nova_config {'DEFAULT/memcached_servers':  value => $memcached_addresses; }

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
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
      galera_cluster_name    => $galera_cluster_name,
      primary_controller     => $primary_controller,
      galera_node_address    => $galera_node_address ,
      galera_nodes           => $galera_nodes,
      custom_setup_class     => $custom_mysql_setup_class,
      mysql_skip_name_resolve => $mysql_skip_name_resolve,
      use_syslog             => $use_syslog,
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
    admin_user            => $admin_user,
    admin_password        => $admin_password,
    public_address        => $public_address,
    internal_address      => $internal_address,
    admin_address         => $admin_address,
    glance_user_password  => $glance_user_password,
    nova_user_password    => $nova_user_password,
    cinder                => $cinder,
    cinder_user_password  => $cinder_user_password,
    quantum               => $quantum,
    bind_host             => $api_bind_address,
    quantum_user_password => $quantum_user_password,
    enabled               => $enabled,
    package_ensure        => $::openstack_keystone_version,
    use_syslog            => $use_syslog,
    syslog_log_facility   => $syslog_log_facility_keystone,
    syslog_log_level      => $syslog_log_level,
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
    auth_uri                  => "http://${service_endpoint}:5000/",
    keystone_host             => $service_endpoint,
    bind_host                 => $api_bind_address,
    enabled                   => $enabled,
    glance_backend            => $glance_backend,
    registry_host             => $service_endpoint,
    use_syslog                => $use_syslog,
    syslog_log_facility       => $syslog_log_facility_glance,
    syslog_log_level          => $syslog_log_level,
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
    $enabled_apis = 'ec2,osapi_compute'
  }
  else {
    $enabled_apis = 'ec2,osapi_compute,osapi_volume'
  } 

  class { 'openstack::nova::controller':
    # Database
    db_host                 => $db_host,
    # Network
    network_manager         => $network_manager,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    public_address          => $public_address,
    public_interface        => $public_interface,
    admin_address           => $admin_address,
    internal_address        => $internal_address,
    private_interface       => $private_interface,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    create_networks         => $create_networks,
    num_networks            => $num_networks,
    network_size            => $network_size,
    multi_host              => $multi_host,
    network_config          => $network_config,
    keystone_host           => $service_endpoint,
    # Quantum
    quantum                 => $quantum,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    quantum_network_node    => $quantum_network_node,
    quantum_netnode_on_cnt  => $quantum_netnode_on_cnt,
    quantum_gre_bind_addr   => $quantum_gre_bind_addr,
    quantum_external_ipinfo => $quantum_external_ipinfo,
    segment_range           => $segment_range,
    tenant_network_type     => $tenant_network_type,
    # Nova
    nova_user_password      => $nova_user_password,
    nova_db_password        => $nova_db_password,
    nova_db_user            => $nova_db_user,
    nova_db_dbname          => $nova_db_dbname,
    # Rabbit
    rabbit_user             => $rabbit_user,
    rabbit_password         => $rabbit_password,
    rabbit_nodes            => $rabbit_nodes,
    rabbit_cluster          => $rabbit_cluster,
    rabbit_node_ip_address  => $rabbit_node_ip_address,
    rabbit_port             => $rabbit_port,
    rabbit_ha_virtual_ip    => $rabbit_ha_virtual_ip,
    # Glance
    glance_api_servers      => $glance_api_servers,
    # General
    verbose                 => $verbose,
    enabled                 => $enabled,
    exported_resources      => $export_resources,
    enabled_apis            => $enabled_apis,
    api_bind_address        => $api_bind_address,
    ensure_package          => $::openstack_version['nova'],
    use_syslog              => $use_syslog,
    syslog_log_facility     => $syslog_log_facility_nova,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_level        => $syslog_log_level,
    nova_rate_limits        => $nova_rate_limits,
    cinder                  => $cinder
  }

  ######### Cinder Controller Services ########
  if $cinder {
    if !defined(Class['openstack::cinder']) {
      class {'openstack::cinder':
      sql_connection       => "mysql://${cinder_db_user}:${cinder_db_password}@${db_host}/${cinder_db_dbname}?charset=utf8",
      rabbit_password      => $rabbit_password,
      rabbit_host          => false,
      rabbit_nodes         => $rabbit_nodes,
      volume_group         => $cinder_volume_group,
      physical_volume      => $nv_physical_volume,
      manage_volumes       => $manage_volumes,
      enabled              => true,
      glance_api_servers   => "${service_endpoint}:9292",
      auth_host            => $service_endpoint,
      bind_host            => $api_bind_address,
      iscsi_bind_host      => $cinder_iscsi_bind_addr,
      cinder_user_password => $cinder_user_password,
      use_syslog           => $use_syslog,
      syslog_log_facility  => $syslog_log_facility_cinder,
      syslog_log_level     => $syslog_log_level,
      cinder_rate_limits   => $cinder_rate_limits,
      rabbit_ha_virtual_ip => $rabbit_ha_virtual_ip,
    }
  } else { 
    if $manage_volumes {
      # Set up nova-volume
      class { 'nova::volume':
        ensure_package => $::openstack_version['nova'],
        enabled        => true,
      }
      class { 'nova::volume::iscsi':
        iscsi_ip_address => $api_bind_address,
        physical_volume  => $nv_physical_volume,
      }
    }
  } 

  if !defined(Class['memcached']){
    class { 'memcached':
      #listen_ip => $api_bind_address,
    } 
  }

  ######## Horizon ########
  class { 'openstack::horizon':
    secret_key        => $secret_key,
    cache_server_ip   => $cache_server_ip,
    package_ensure    => $::openstack_version['horizon'],
    bind_address      => $api_bind_address,
    cache_server_port => $cache_server_port,
    swift             => $swift,
    quantum           => $quantum,
    horizon_app_links => $horizon_app_links,
    keystone_host     => $service_endpoint,
    use_ssl           => $horizon_use_ssl,
    verbose           => $verbose,
    use_syslog        => $use_syslog,
  }

}

