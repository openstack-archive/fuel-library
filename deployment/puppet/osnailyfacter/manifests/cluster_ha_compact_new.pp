class osnailyfacter::cluster_ha {


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
$nova-network_params  = parsejson($::nova-network_parameters)
$base_syslog_hash     = parsejson($::base_syslog)
$syslog_hash          = parsejson($::syslog)

$tenant_network_type  = $quantum_params['tenant_network_type']
$segment_range        = $quantum_params['segment_range']
$rabbit_user          = $rabbit_hash['user']
$fixed_network_range  = $nova-network_params['fixed_network_range']
$vlan_start           = $nova-network_params['vlan_start']
$network_manager      = "nova.network.manager.${nova-network_params['network_manager']}"
$network_size         = $nova-network_params['network_size']
$cinder_nodes          = ['controller']


##
$internal_br         = 'br-mgmt'
$public_br           = 'br-ex'

$verbose = true
$debug = true

$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx']
##CALCULATED PARAMETERS

##NO NEED TO CHANGE

$controller_node_public  = $internal_virtual_ip
$swift_proxies = $controller_internal_addresses


$vips = { # Do not convert to ARRAY, It can't work in 2.7
  public_old => {
    nic    => $public_int,
    ip     => $public_vip,
  },
  management_old => {
    nic    => $internal_int,
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

$base_syslog_rserver  = {
  'remote_type' => 'udp',
  'server' => $base_syslog_hash['syslog_server'],
  'port' => $base_syslog_hash['syslog_port']
}


$syslog_rserver = {
  'remote_type' => $syslog_hash['syslog_transport'],
  'server' => $syslog_hash['syslog_server'],
  'port' => $syslog_hash['syslog_port'],
}

if $syslog_hash['syslog_server'] != "" and $syslog_hash['syslog_port'] != "" and $syslog_hash['syslog_transport'] != "" {
  $rservers = [$base_syslog_rserver, $syslog_rserver]
}
else {
  $rservers = [$base_syslog_rserver]
}

$quantum_host            = $management_vip

##REFACTORING NEEDED


##TODO: simply parse nodes array
$controller_internal_addresses = parsejson($ctrl_management_addresses)
$controller_public_addresses = parsejson($ctrl_public_addresses)
$controller_storage_addresses = parsejson($ctrl_storage_addresses)
$controller_hostnames = keys($controller_internal_addresses)
$controller_nodes = values($controller_internal_addresses)

$internal_address = $node[0]['internal_address']
$public_address = $node[0]['public_address']
$quantum_gre_bind_addr = $internal_address

$swift_local_net_ip      = $internal_address

$cinder_iscsi_bind_addr = $internal_address

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
$master_swift_proxy_nodes = filter_nodes($nodes,'role','primary-controller')
$master_swift_proxy_ip = $master_swift_proxy_nodes[0]['internal_address']



if $::hostname == $master_hostname {
  $primary_proxy = true
  $primary_controller = true
} else {
  $primary_proxy = false
  $primary_controller = false
}



#HARDCODED PARAMETERS

### Syslog ###
# Enable error messages reporting to rsyslog. Rsyslog must be installed in this case.
$use_syslog = true
# Default log level would have been used, if non verbose and non debug
$syslog_log_level             = 'ERROR'
# Syslog facilities for main openstack services, choose any, may overlap if needed
# local0 is reserved for HA provisioning and orchestration services,
# local1 is reserved for openstack-dashboard
$syslog_log_facility_glance   = 'LOCAL2'
$syslog_log_facility_cinder   = 'LOCAL3'
$syslog_log_facility_quantum  = 'LOCAL4'
$syslog_log_facility_nova     = 'LOCAL6'
$syslog_log_facility_keystone = 'LOCAL7'


$multi_host              = true
$manage_volumes          = false
$glance_backend          = 'swift'
$quantum_netnode_on_cnt  = true
$swift_loopback = 'loopback'

if $use_syslog {
  class { "::openstack::logging":
    stage          => 'first',
    role           => 'client',
    show_timezone => true,
    # log both locally include auth, and remote
    log_remote     => true,
    log_local      => true,
    log_auth_local => true,
    # keep four weekly log rotations, force rotate if 300M size have exceeded
    rotation       => 'weekly',
    keep           => '4',
    # should be > 30M
    limitsize      => '300M',
    # remote servers to send logs to
    rservers       => [{'remote_type'=>'udp', 'server'=>'master', 'port'=>'514'},],
    # should be true, if client is running at virtual node
    virtual        => true,
    # facilities
    syslog_log_facility_glance   => $syslog_log_facility_glance,
    syslog_log_facility_cinder   => $syslog_log_facility_cinder,
    syslog_log_facility_quantum  => $syslog_log_facility_quantum,
    syslog_log_facility_nova     => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    # Rabbit doesn't support syslog directly, should be >= syslog_log_level,
    # otherwise none rabbit's messages would have gone to syslog
    rabbit_log_level => $syslog_log_level,
  }
}



 # Quantum is turned off

$mirror_type = 'external'
 # Quantum is turned off

Exec { logoutput => true }





class compact_controller {
  class { 'openstack::controller_ha':
    controller_public_addresses   => $controller_public_addresses,
    controller_internal_addresses => $controller_internal_addresses,
    internal_address              => $internal_address,
    public_interface              => $public_interface,
    internal_interface            => $management_interface,
    private_interface             => $fixed_interface,
    internal_virtual_ip           => $management_vip,
    public_virtual_ip             => $public_vip,
    primary_controller            => $primary_controller,
    floating_range                => false,
    fixed_range                   => $fixed_network_range,
    multi_host                    => $multi_host,
    network_manager               => $network_manager,
    num_networks                  => $num_networks,
    network_size                  => $network_size,
    network_config                => $network_config,
    verbose                       => $verbose,
    debug                         => $debug,
    auto_assign_floating_ip       => $bool_auto_assign_floating_ip,
    mysql_root_password           => $mysql_hash[root_password],
    admin_email                   => $access_hash[email],
    admin_user                    => $access_hash[user],
    admin_password                => $access_hash[password],
    keystone_db_password          => $keystone_hash[db_password],
    keystone_admin_token          => $keystone_hash[admin_token],
    keystone_admin_tenant         => $access_hash[tenant],
    glance_db_password            => $glance_hash[db_password],
    glance_user_password          => $glance_hash[user_password],
    nova_db_password              => $nova_hash[db_password],
    nova_user_password            => $nova_hash[user_password],
    rabbit_password               => $rabbit_hash[password],
    rabbit_user                   => $rabbit_hash[user],
    rabbit_nodes                  => $controller_nodes,
    memcached_servers             => $controller_nodes,
    export_resources              => false,
    glance_backend                => $glance_backend,
    swift_proxies                 => $controller_internal_addresses,
    quantum                       => $quantum,
    quantum_user_password         => $quantum_hash[user_password],
    quantum_db_password           => $quantum_hash[db_password],
    tenant_network_type           => $tenant_network_type,
    segment_range                 => $segment_range,
    cinder                        => true,
    cinder_user_password          => $cinder_hash[user_password],
    cinder_iscsi_bind_addr        => $internal_address,
    cinder_db_password            => $cinder_hash[db_password],
    manage_volumes                => false,
    galera_nodes                  => $controller_nodes,
    mysql_skip_name_resolve       => true,
    use_syslog                    => true,
  }

  class { "::rsyslog::client":
    log_local => true,
    log_auth_local => true,
    rservers => $rservers,
  }

  class { 'swift::keystone::auth':
     password         => $swift_hash[user_password],
     public_address   => $public_vip,
     internal_address => $management_vip,
     admin_address    => $management_vip,
  }
}

class virtual_ips () {
  cluster::virtual_ips { $vip_keys:
    vips => $vips,
  }
}



  case $role {
    "controller" : {
      include osnailyfacter::test_controller

	
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

      class { compact_controller: }
      class { 'openstack::swift::storage_node':
        storage_type          => 'loopback',
        loopback_size         => '5243780',
        swift_zone            => $uid,
        swift_local_net_ip    => $storage_address,
        master_swift_proxy_ip => $controller_internal_addresses[$master_hostname],
        sync_rings            => ! $primary_proxy
      }
      if $primary_proxy {
        ring_devices {'all':
          storages => parsejson($nodes)
        }
      }
      class { 'openstack::swift::proxy':
        swift_user_password     => $swift_hash[user_password],
        swift_proxies           => $controller_internal_addresses,
        primary_proxy           => $primary_proxy,
        controller_node_address => $management_vip,
        swift_local_net_ip      => $internal_address,
        master_swift_proxy_ip   => $controller_internal_addresses[$master_hostname],
      }
      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $start_guests_on_host_boot }
      nova_config { 'DEFAULT/use_cow_images': value => $use_cow_images }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $compute_scheduler_driver }

      if $hostname == $master_hostname {
        class { 'openstack::img::cirros':
          os_username => shellescape($access_hash[user]),
          os_password => shellescape($access_hash[password]),
          os_tenant_name => shellescape($access_hash[tenant]),
          os_auth_url => "http://${management_vip}:5000/v2.0/",
          img_name    => "TestVM",
          stage          => 'glance-image',
        }
        nova::manage::floating{$floating_hash:}
        Class[glance::api]                    -> Class[openstack::img::cirros]
        Class[openstack::swift::storage_node] -> Class[openstack::img::cirros]
        Class[openstack::swift::proxy]        -> Class[openstack::img::cirros]
        Service[swift-proxy]                  -> Class[openstack::img::cirros]
      }
    }

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $public_interface,
        private_interface      => $fixed_interface,
        internal_address       => $internal_address,
        libvirt_type           => $libvirt_type,
        fixed_range            => $fixed_network_range,
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => "mysql://nova:${nova_hash[db_password]}@${management_vip}/nova",
        rabbit_nodes           => $controller_nodes,
        rabbit_password        => $rabbit_hash[password],
        rabbit_user            => $rabbit_user,
        rabbit_ha_virtual_ip   => $management_vip,
        auto_assign_floating_ip => $bool_auto_assign_floating_ip,
        glance_api_servers     => "${management_vip}:9292",
        vncproxy_host          => $public_vip,
        verbose                => $verbose,
        vnc_enabled            => true,
        manage_volumes         => false,
        nova_user_password     => $nova_hash[user_password],
        cache_server_ip        => $controller_nodes,
        service_endpoint       => $management_vip,
        cinder                 => true,
        cinder_iscsi_bind_addr => $internal_address,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        db_host                => $management_vip,
        quantum                => $quantum,
        quantum_host           => $quantum_host,
        quantum_sql_connection => $quantum_sql_connection,
        quantum_user_password  => $quantum_user_password,
        tenant_network_type    => $tenant_network_type,
        segment_range          => $segment_range,
        use_syslog             => true,
      }

      class { "::rsyslog::client":
        log_local => true,
        log_auth_local => true,
        rservers => $rservers,
      }
      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $start_guests_on_host_boot }
      nova_config { 'DEFAULT/use_cow_images': value => $use_cow_images }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $compute_scheduler_driver }
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
}
