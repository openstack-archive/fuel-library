class osnailyfacter::cluster_ha_cli {


##PARAMETERS DERIVED FROM YAML FILE



$nova_hash            = parsejson($::nova)
$quantum_hash         = parsejson($::quantum)
$mysql_hash           = parsejson($::mysql)
$rabbit_hash          = parsejson($::rabbit)
$glance_hash          = parsejson($::glance)
$keystone_hash        = parsejson($::keystone)
$swift_hash           = parsejson($::swift)
$cinder_hash          = parsejson($::cinder)
$access_hash          = parsejson($::access)
$floating_hash        = parsejson($::floating_network_range)
$quantum_params       = parsejson($::quantum_parameters)
$novanetwork_params  = parsejson($::novanetwork_parameters)
$nodes_hash           = parsejson($::nodes)
$tenant_network_type  = $quantum_params['tenant_network_type']
$segment_range        = $quantum_params['segment_range']
$rabbit_user          = $rabbit_hash['user']
$fixed_network_range  = $novanetwork_params['fixed_network_range']
$vlan_start           = $novanetwork_params['vlan_start']
$network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"
$network_size         = $novanetwork_params['network_size']
$cinder_nodes          = ['controller']


##
$verbose = true
$debug = true
$ntp_servers = ['pool.ntp.org']
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx']
##CALCULATED PARAMETERS

##NO NEED TO CHANGE

$node = filter_nodes($nodes_hash,'name',$::hostname)
if empty($node) {
  fail("Node $::hostname is not defined in the hash structure")
}

$vips = { # Do not convert to ARRAY, It can't work in 2.7
  public_old => {
    nic    => $::public_int,
    ip     => $public_vip,
  },
  management_old => {
    nic    => $::internal_int,
    ip     => $management_vip,
  },
}

$vip_keys = keys($vips)

if ($cinder) {
  if (member($cinder_nodes,'all')) {
    $is_cinder_node = true
  } elsif (member($cinder_nodes,$::hostname)) {
    $is_cinder_node = true
  } elsif (member($cinder_nodes,$internal_address)) {
    $is_cinder_node = true
  } elsif ($node[0]['role'] =~ /controller/ ) {
    $is_cinder_node = member($cinder_nodes,'controller')
  } else {
    $is_cinder_node = member($cinder_nodes,$node[0]['role'])
  }
} else {
  $is_cinder_node = false
}

$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"
$quantum_host            = $management_vip

##REFACTORING NEEDED


##TODO: simply parse nodes array
$controllers = merge_arrays(filter_nodes($nodes_hash,'role','primary-controller'), filter_nodes($nodes_hash,'role','controller'))
$controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
$controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
$controller_storage_addresses = nodes_to_hash($controllers,'name','storage_address')
$controller_hostnames = keys($controller_internal_addresses)
$controller_nodes = values($controller_internal_addresses)
$swift_proxy_nodes = merge_arrays(filter_nodes($nodes_hash,'role','primary-swift-proxy'),filter_nodes($nodes,'role','swift-proxy'))
$swift_proxies = nodes_to_hash($swift_proxy_nodes,'name','internal_address')
$swift_storages = filter_nodes($nodes_hash, 'role', 'storage')
$controller_node_public  = $management_vip
$swift_proxies = $controller_internal_addresses
$quantum_metadata_proxy_shared_secret = $quantum_params['metadata_proxy_shared_secret']
$quantum_gre_bind_addr = $::internal_address

$swift_local_net_ip      = $::internal_address

$cinder_iscsi_bind_addr = $::internal_address

if $auto_assign_floating_ip == 'true' {
  $bool_auto_assign_floating_ip = true
} else {
  $bool_auto_assign_floating_ip = false
}

$network_config = {
  'vlan_start'     => $vlan_start,
}


if $node[0]['role'] == 'primary-controller' {
  $primary_proxy = true
} else {
  $primary_proxy = false
}
if $node[0]['role'] == 'primary-controller' {
  $primary_controller = true
} else {
  $primary_controller = false
}
$master_swift_proxy_nodes = filter_nodes($nodes_hash,'role','primary-swift-proxy')
$master_swift_proxy_ip = $master_swift_proxy_nodes[0]['internal_address']
$master_hostname = filter_nodes($nodes_hash,'role','primary-controller')[0]['name']

#HARDCODED PARAMETERS
$nova_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000, 'GET' => 1000,
  'DELETE' => 1000
}
$cinder_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000, 'GET' => 1000,
  'DELETE' => 1000
}

$multi_host              = true
$manage_volumes          = false
$glance_backend          = 'swift'
$quantum_netnode_on_cnt  = true
$swift_loopback = 'loopback'


$mirror_type = 'external'

class ha_controller (
  $quantum_network_node = $quantum_netnode_on_cnt
) {
  ###
  # cluster init
  class { '::cluster': stage => 'corosync_setup' } ->
  class { 'virtual_ips':
    stage => 'corosync_setup'
  }
  include ::haproxy::params
  class { 'cluster::haproxy':
    global_options   => merge($::haproxy::params::global_options, {'log' => "/dev/log local0"}),
    defaults_options => merge($::haproxy::params::defaults_options, {'mode' => 'http'}),
    stage => 'cluster_head',
  }
  #
  ###

  if $nagios {
    class {'nagios':
      proj_name       => $proj_name,
      services        => [
        'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
        'nova-consoleauth', 'nova-cert', 'haproxy', 'nova-api', 'glance-api',
        'glance-registry','horizon', 'rabbitmq', 'mysql',
      ],
      whitelist       => ['127.0.0.1', $nagios_master],
      hostgroup       => 'controller',
    }
  }

  class { 'openstack::controller_ha':
    controller_public_addresses   => $controller_public_addresses,
    controller_internal_addresses => $controller_internal_addresses,
    internal_address        => $internal_address,
    public_interface        => $public_int,
    internal_interface      => $internal_int,
    private_interface       => $private_interface,
    internal_virtual_ip     => $internal_virtual_ip,
    public_virtual_ip       => $public_virtual_ip,
    primary_controller      => $primary_controller,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    multi_host              => $multi_host,
    network_manager         => $network_manager,
    num_networks            => $num_networks,
    network_size            => $network_size,
    network_config          => { 'vlan_start' => $vlan_start },
    verbose                 => $verbose,
    debug                   => $debug,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    queue_provider          => $queue_provider,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    rabbit_nodes            => $controller_hostnames,
    qpid_password           => $rabbit_password,
    qpid_user               => $rabbit_user,
    qpid_nodes              => [$internal_virtual_ip],
    memcached_servers       => $controller_hostnames,
    export_resources        => false,
    glance_backend          => $glance_backend,
    swift_proxies           => $swift_proxies,
    quantum                 => $quantum,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    quantum_db_user         => $quantum_db_user,
    quantum_db_dbname       => $quantum_db_dbname,
    quantum_network_node    => $quantum_network_node,
    quantum_netnode_on_cnt  => $quantum_netnode_on_cnt,
    quantum_gre_bind_addr   => $quantum_gre_bind_addr,
    quantum_external_ipinfo => $external_ipinfo,
    tenant_network_type     => $tenant_network_type,
    segment_range           => $segment_range,
    cinder                  => $cinder,
    cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
    manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
    galera_nodes            => $controller_hostnames,
    custom_mysql_setup_class => $custom_mysql_setup_class,
    nv_physical_volume      => $nv_physical_volume,
    use_syslog              => $use_syslog,
    syslog_log_level        => $syslog_log_level,
    syslog_log_facility_glance   => $syslog_log_facility_glance,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_facility_nova => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    nova_rate_limits        => $nova_rate_limits,
    cinder_rate_limits      => $cinder_rate_limits,
    horizon_use_ssl         => $horizon_use_ssl,
    use_unicast_corosync    => $use_unicast_corosync,
    ha_provider             => $ha_provider
  }
  class { 'swift::keystone::auth':
    password         => $swift_user_password,
    public_address   => $public_virtual_ip,
    internal_address => $internal_virtual_ip,
    admin_address    => $internal_virtual_ip,
  }
}

# Definition of OpenStack controller nodes.
include stdlib
case $role {
 /controller/ : {
 class { 'operatingsystem::checksupported':
      stage => 'first'
  }

  class { ha_controller: }
}


# Definition of OpenStack compute nodes.
/compute/ : {
  class { 'operatingsystem::checksupported':
      stage => 'first'
  }

  if $nagios {
    class {'nagios':
      proj_name       => $proj_name,
      services        => [
        'host-alive', 'nova-compute','nova-network','libvirt'
      ],
      whitelist       => ['127.0.0.1', $nagios_master],
      hostgroup       => 'compute',
    }
  }

  class { 'openstack::compute':
    public_interface       => $public_int,
    private_interface      => $private_interface,
    internal_address       => $internal_address,
    libvirt_type           => 'kvm',
    fixed_range            => $fixed_range,
    network_manager        => $network_manager,
    network_config         => { 'vlan_start' => $vlan_start },
    multi_host             => $multi_host,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    sql_connection         => "mysql://nova:${nova_db_password}@${internal_virtual_ip}/nova",
    queue_provider         => $queue_provider,
    rabbit_nodes           => $controller_hostnames,
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    rabbit_ha_virtual_ip   => $internal_virtual_ip,
    qpid_password          => $rabbit_password,
    qpid_user              => $rabbit_user,
    qpid_nodes             => [$internal_virtual_ip],
    glance_api_servers     => "${internal_virtual_ip}:9292",
    vncproxy_host          => $public_virtual_ip,
    verbose                => $verbose,
    debug                  => $debug,
    vnc_enabled            => true,
    nova_user_password     => $nova_user_password,
    cache_server_ip        => $controller_hostnames,
    service_endpoint       => $internal_virtual_ip,
    quantum                => $quantum,
    quantum_sql_connection => $quantum_sql_connection,
    quantum_user_password  => $quantum_user_password,
    quantum_host           => $internal_virtual_ip,
    tenant_network_type    => $tenant_network_type,
    segment_range          => $segment_range,
    cinder                 => $cinder,
    cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
    manage_volumes         => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
    nv_physical_volume     => $nv_physical_volume,
    db_host                => $internal_virtual_ip,
    cinder_rate_limits     => $cinder_rate_limits,
    ssh_private_key        => 'puppet:///ssh_keys/openstack',
    ssh_public_key         => 'puppet:///ssh_keys/openstack.pub',
    use_syslog             => $use_syslog,
    syslog_log_level       => $syslog_log_level,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    nova_rate_limits       => $nova_rate_limits,
  }
}

# Definition of the first OpenStack Swift node.
/storage/ : {
  class { 'operatingsystem::checksupported':
      stage => 'setup'
  }

  class {'::node_netconfig':
    mgmt_ipaddr    => $::internal_address,
    mgmt_netmask   => $::internal_netmask,
    public_ipaddr  => $::public_address,
    public_netmask => $::public_netmask,
    stage          => 'netconfig',
  }

  if $nagios {
    class {'nagios':
      proj_name       => $proj_name,
      services        => [
        'host-alive', 'swift-account', 'swift-container', 'swift-object',
      ],
      whitelist       => ['127.0.0.1', $nagios_master],
      hostgroup       => 'swift-storage',
    }
  }

  $swift_zone = $node[0]['swift_zone']

  class { 'openstack::swift::storage_node':
    storage_type           => $swift_loopback,
    swift_zone             => $swift_zone,
    swift_local_net_ip     => $swift_local_net_ip,
    master_swift_proxy_ip  => $master_swift_proxy_ip,
    cinder                 => $cinder,
    cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
    manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
    nv_physical_volume     => $nv_physical_volume,
    db_host                => $internal_virtual_ip,
    service_endpoint       => $internal_virtual_ip,
    cinder_rate_limits     => $cinder_rate_limits,
    queue_provider         => $queue_provider,
    rabbit_nodes           => $controller_hostnames,
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    rabbit_ha_virtual_ip   => $internal_virtual_ip,
    qpid_password          => $rabbit_password,
    qpid_user              => $rabbit_user,
    qpid_nodes             => [$internal_virtual_ip],
    sync_rings             => ! $primary_proxy,
    syslog_log_level => $syslog_log_level,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
  }

}

# Definition of OpenStack Swift proxy nodes.
/swift-proxy/: {
  class { 'operatingsystem::checksupported':
      stage => 'setup'
  }

  class {'::node_netconfig':
    mgmt_ipaddr    => $::internal_address,
    mgmt_netmask   => $::internal_netmask,
    public_ipaddr  => $::public_address,
    public_netmask => $::public_netmask,
    stage          => 'netconfig',
  }

  if $nagios {
    class {'nagios':
      proj_name       => $proj_name,
      services        => ['host-alive', 'swift-proxy'],
      whitelist       => ['127.0.0.1', $nagios_master],
      hostgroup       => 'swift-proxy',
    }
  }

  if $primary_proxy {
    ring_devices {'all':
      storages => filter_nodes($nodes, 'role', 'storage')
    }
  }

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_user_password,
    swift_proxies           => $swift_proxies,
    primary_proxy           => $primary_proxy,
    controller_node_address => $internal_virtual_ip,
    swift_local_net_ip      => $swift_local_net_ip,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
  }
}

# Definition of OpenStack Quantum node.
/quantum/ : {
  class { 'operatingsystem::checksupported':
      stage => 'first'
  }

  class {'::node_netconfig':
      mgmt_ipaddr    => $::internal_address,
      mgmt_netmask   => $::internal_netmask,
      public_ipaddr  => 'none',
      save_default_gateway => true,
      stage          => 'netconfig',
  }
  if ! $quantum_netnode_on_cnt {
    class { 'openstack::quantum_router':
      db_host               => $internal_virtual_ip,
      service_endpoint      => $internal_virtual_ip,
      auth_host             => $internal_virtual_ip,
      nova_api_vip          => $internal_virtual_ip,
      internal_address      => $internal_address,
      public_interface      => $public_int,
      private_interface     => $private_interface,
      floating_range        => $floating_range,
      fixed_range           => $fixed_range,
      create_networks       => $create_networks,
      verbose               => $verbose,
      debug                 => $debug,
      queue_provider        => $queue_provider,
      rabbit_password       => $rabbit_password,
      rabbit_user           => $rabbit_user,
      rabbit_nodes          => $controller_hostnames,
      rabbit_ha_virtual_ip  => $internal_virtual_ip,
      qpid_password         => $rabbit_password,
      qpid_user             => $rabbit_user,
      qpid_nodes            => [$internal_virtual_ip],
      quantum               => $quantum,
      quantum_user_password => $quantum_user_password,
      quantum_db_password   => $quantum_db_password,
      quantum_db_user       => $quantum_db_user,
      quantum_db_dbname     => $quantum_db_dbname,
      quantum_netnode_on_cnt=> false,
      quantum_network_node  => true,
      tenant_network_type   => $tenant_network_type,
      segment_range         => $segment_range,
      external_ipinfo       => $external_ipinfo,
      api_bind_address      => $internal_address,
      use_syslog            => $use_syslog,
      syslog_log_level      => $syslog_log_level,
      syslog_log_facility_quantum => $syslog_log_facility_quantum,
    }
    class { 'openstack::auth_file':
      admin_password       => $admin_password,
      keystone_admin_token => $keystone_admin_token,
      controller_node      => $internal_virtual_ip,
      before               => Class['openstack::quantum_router'],
    }
  }
}

    "cinder" : {
      include keystone::python
      package { 'python-amqp':
        ensure => present
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${management_vip}/cinder?charset=utf8",
        glance_api_servers   => "${management_vip}:9292",
        rabbit_password      => $rabbit_hash[password],
        rabbit_host          => false,
        rabbit_nodes         => $management_vip,
        volume_group         => 'cinder',
        manage_volumes       => true,
        enabled              => true,
        auth_host            => $management_vip,
        iscsi_bind_host      => $storage_address,
        cinder_user_password => $cinder_hash[user_password],
        use_syslog           => true,
      }
      class { "::rsyslog::client":
        log_local => true,
        log_auth_local => true,
        rservers => $rservers,
      }
    }
}
