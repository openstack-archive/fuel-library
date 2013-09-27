class osnailyfacter::cluster_ha {

##PARAMETERS DERIVED FROM YAML FILE

if $::use_quantum {
  $quantum_hash   = $::fuel_settings['quantum_access']
  $quantum_params = $::fuel_settings['quantum_parameters']
  $novanetwork_params  = {}
} 
else {
  $quantum_hash = {}
  $quantum_params = {}
  $novanetwork_params  = $::fuel_settings['novanetwork_parameters']
}

if $cinder_nodes {
   $cinder_nodes_array   = $::fuel_settings['cinder_nodes']
}
else {
  $cinder_nodes_array = []
}


$nova_hash            = $::fuel_settings['nova']
$mysql_hash           = $::fuel_settings['mysql']
$rabbit_hash          = $::fuel_settings['rabbit']
$glance_hash          = $::fuel_settings['glance']
$keystone_hash        = $::fuel_settings['keystone']
$swift_hash           = $::fuel_settings['swift']
$cinder_hash          = $::fuel_settings['cinder']
$access_hash          = $::fuel_settings['access']
$nodes_hash           = $::fuel_settings['nodes']
$mp_hash              = $::fuel_settings['mp']
$network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"
$network_size         = $novanetwork_params['network_size']
$num_networks         = $novanetwork_params['num_networks']
$tenant_network_type  = $quantum_params['tenant_network_type']
$segment_range        = $quantum_params['segment_range']
$vlan_start           = $novanetwork_params['vlan_start']

if !$rabbit_hash[user]
{
  $rabbit_hash[user] = 'nova'
}

$rabbit_user          = $rabbit_hash['user']

if $::use_quantum {
$floating_hash =  $::fuel_settings['floating_network_range']
}
else {
  $floating_hash = {}
  $floating_ips_range = $::fuel_settings['floating_network_range']
}


if !$::fuel_settings['swift_partition']
{
  $swift_partition = '/var/lib/glance/node'
}


##CALCULATED PARAMETERS


##NO NEED TO CHANGE

$node = filter_nodes($nodes_hash,'name',$::hostname)
if empty($node) {
  fail("Node $::hostname is not defined in the hash structure")
}

$vips = { # Do not convert to ARRAY, It can't work in 2.7
  public_old => {
    nic    => $::public_int,
    ip     => $::fuel_settings['public_vip'],
  },
  management_old => {
    nic    => $::internal_int,
    ip     => $::fuel_settings['management_vip'],
  },
}

$vip_keys = keys($vips)

if ($cinder) {
  if (member($cinder_nodes_array,'all')) {
    $is_cinder_node = true
  } elsif (member($cinder_nodes_array,$::hostname)) {
    $is_cinder_node = true
  } elsif (member($cinder_nodes_array,$internal_address)) {
    $is_cinder_node = true
  } elsif ($node[0]['role'] =~ /controller/ ) {
    $is_cinder_node = member($cinder_nodes_array,'controller')
  } else {
    $is_cinder_node = member($cinder_nodes_array,$node[0]['role'])
  }
} else {
  $is_cinder_node = false
}

$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"

$quantum_host            = $::fuel_settings['management_vip']

##REFACTORING NEEDED


##TODO: simply parse nodes array
$controllers = merge_arrays(filter_nodes($nodes_hash,'role','primary-controller'), filter_nodes($nodes_hash,'role','controller'))
$controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
$controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
$controller_storage_addresses = nodes_to_hash($controllers,'name','storage_address')
$controller_hostnames = keys($controller_internal_addresses)
$controller_nodes = sort(values($controller_internal_addresses))
$controller_node_public  = $::fuel_settings['public_vip']
$controller_node_address = $::fuel_settings['management_vip']
$mountpoints = filter_hash($mp_hash,'point')
$swift_proxies = $controller_storage_addresses
$quantum_metadata_proxy_shared_secret = $quantum_params['metadata_proxy_shared_secret']

$quantum_gre_bind_addr = $::internal_address

$swift_local_net_ip      = $::storage_address

$cinder_iscsi_bind_addr = $::storage_address

#TODO: awoodward fix static $use_ceph
if ($::use_ceph) {
  $primary_mons   = filter_nodes($nodes_hash,'role','primary-controller')
  $primary_mon    = $primary_mons[0]['name']
  $glance_backend = 'ceph'
  class {'ceph':
    primary_mon  => $primary_mon,
    cluster_node_address => $controller_node_address,
  }
} else {
  $glance_backend = 'swift'
}

$network_config = {
  'vlan_start'     => $vlan_start,
}

if !$::fuel_settings['verbose']
{
  $verbose = false
}

if !$::fuel_settings['debug']
{
  $debug = false
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
$master_swift_proxy_nodes = filter_nodes($nodes_hash,'role','primary-controller')
$master_swift_proxy_ip = $master_swift_proxy_nodes[0]['internal_address']
#$master_hostname = $master_swift_proxy_nodes[0]['name']

#HARDCODED PARAMETERS

$multi_host              = true
$manage_volumes          = false
#Moved to CEPH if block
#$glance_backend          = 'swift'
$quantum_netnode_on_cnt  = true
$swift_loopback = false
$mirror_type = 'external'
Exec { logoutput => true }




class compact_controller (
  $quantum_network_node = $quantum_netnode_on_cnt
) {

  class {'osnailyfacter::apache_api_proxy':}

  class { 'openstack::controller_ha':
    controller_public_addresses   => $controller_public_addresses,
    controller_internal_addresses => $controller_internal_addresses,
    internal_address              => $internal_address,
    public_interface              => $::public_int,
    internal_interface            => $::internal_int,
    private_interface             => $::fuel_settings['fixed_interface'],
    internal_virtual_ip           => $::fuel_settings['management_vip'],
    public_virtual_ip             => $::fuel_settings['public_vip'],
    primary_controller            => $primary_controller,
    floating_range                => $::use_quantum ? { true=>$floating_hash, default=>false},
    fixed_range                   => $::fuel_settings['fixed_network_range'],
    multi_host                    => $multi_host,
    network_manager               => $network_manager,
    num_networks                  => $num_networks,
    network_size                  => $network_size,
    network_config                => $network_config,
    debug                         => $debug ? { 'true' => true, true => true, default=> false },
    verbose                       => $verbose ? { 'true' => true, true => true, default=> false },
    queue_provider                => $::queue_provider,
    qpid_password                 => $rabbit_hash[password],
    qpid_user                     => $rabbit_hash[user],
    qpid_nodes                    => [$::fuel_settings['management_vip']],
    auto_assign_floating_ip       => $::fuel_settings['auto_assign_floating_ip'],
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
    swift_proxies                 => $swift_proxies,
    quantum                       => $::use_quantum,
    quantum_user_password         => $quantum_hash[user_password],
    quantum_db_password           => $quantum_hash[db_password],
    quantum_network_node          => $quantum_network_node,
    quantum_netnode_on_cnt        => $quantum_netnode_on_cnt,
    quantum_gre_bind_addr         => $quantum_gre_bind_addr,
    quantum_external_ipinfo       => $external_ipinfo,
    tenant_network_type           => $tenant_network_type,
    segment_range                 => $segment_range,
    cinder                        => true,
    cinder_user_password          => $cinder_hash[user_password],
    cinder_iscsi_bind_addr        => $cinder_iscsi_bind_addr,
    cinder_db_password            => $cinder_hash[db_password],
    cinder_volume_group           => "cinder",
    manage_volumes                => $is_cinder_node,
    galera_nodes                  => $controller_nodes,
    custom_mysql_setup_class      => $custom_mysql_setup_class,
    mysql_skip_name_resolve       => true,
    use_syslog                    => true,
    syslog_log_level              => $syslog_log_level,
    syslog_log_facility_glance   => $syslog_log_facility_glance,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_facility_nova => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    nova_rate_limits        => $nova_rate_limits,
    cinder_rate_limits      => $cinder_rate_limits,
    horizon_use_ssl         => $::fuel_settings['horizon_use_ssl'],
    use_unicast_corosync    => $::fuel_settings['use_unicast_corosync'],
  }


  class { 'swift::keystone::auth':
    password         => $swift_hash[user_password],
    public_address   => $::fuel_settings['piblic_vip'],
    internal_address => $::fuel_settings['management_vip'],
    admin_address    => $::fuel_settings['management_vip'],
  }
}

class virtual_ips () {
  cluster::virtual_ips { $vip_keys:
    vips => $vips,
  }
}



  case $::fuel_settings['role'] {
    /controller/ : {
      include osnailyfacter::test_controller

  $swift_zone = $node[0]['swift_zone']

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
        storage_type          => $swift_loopback,
        loopback_size         => '5243780',
        storage_mnt_base_dir  => $swift_partition,
        storage_devices       => $mountpoints,
        swift_zone            => $swift_zone,
        swift_local_net_ip    => $storage_address,
        master_swift_proxy_ip   => $master_swift_proxy_ip,
        sync_rings            => ! $primary_proxy,
        syslog_log_level      => $syslog_log_level,
        debug                 => $debug ? { 'true' => true, true => true, default=> false },
        verbose               => $verbose ? { 'true' => true, true => true, default=> false },
      }
      if $primary_proxy {
        ring_devices {'all': storages => $controllers }
      }
      class { 'openstack::swift::proxy':
        swift_user_password     => $swift_hash[user_password],
        swift_proxies           => $controller_internal_addresses,
        primary_proxy           => $primary_proxy,
        controller_node_address => $::fuel_settings['management_vip'],
        swift_local_net_ip      => $swift_local_net_ip,
        master_swift_proxy_ip   => $master_swift_proxy_ip,
        syslog_log_level        => $syslog_log_level,
        debug                   => $debug ? { 'true' => true, true => true, default=> false },
        verbose                 => $verbose ? { 'true' => true, true => true, default=> false },
      }
      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

#TODO: fix this so it dosn't break ceph
      if $::hostname == $::last_controller {
        class { 'openstack::img::cirros':
          os_username => shellescape($access_hash[user]),
          os_password => shellescape($access_hash[password]),
          os_tenant_name => shellescape($access_hash[tenant]),
          os_auth_url => "http://${::fuel_settings['management_vip']}:5000/v2.0/",
          img_name    => "TestVM",
          stage          => 'glance-image',
        }
        Class[glance::api]                    -> Class[openstack::img::cirros]
        Class[openstack::swift::storage_node] -> Class[openstack::img::cirros]
        Class[openstack::swift::proxy]        -> Class[openstack::img::cirros]
        Service[swift-proxy]                  -> Class[openstack::img::cirros]

      }
      if ! $::use_quantum {
        nova_floating_range{ $floating_ips_range:
          ensure          => 'present',
          pool            => 'nova',
          username        => $access_hash[user],
          api_key         => $access_hash[password],
          auth_method     => 'password',
          auth_url        => "http://${::fuel_settings['management_vip']}:5000/v2.0/",
          authtenant_name => $access_hash[tenant],
        }
        Class[nova::api] -> Nova_floating_range <| |>
      }
      if defined(Class['ceph']){
        Class['openstack::controller'] -> Class['ceph::glance']
        Class['glance::api']           -> Class['ceph::glance']
        Class['openstack::controller'] -> Class['ceph::cinder']
      }
     }

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $::public_int,
        private_interface      => $::fuel_settings['fixed_interface'],
        internal_address       => $internal_address,
        libvirt_type           => $::fuel_settings['libvirt_type'],
        fixed_range            => $::fuel_settings['fixed_network_range'],
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => "mysql://nova:${nova_hash[db_password]}@${::fuel_settings['management_vip']}/nova",
        queue_provider         => $::queue_provider,
        qpid_password          => $rabbit_hash[password],
        qpid_user              => $rabbit_hash[user],
        qpid_nodes             => [$::fuel_settings['management_vip']],
        rabbit_nodes           => $controller_nodes,
        rabbit_password        => $rabbit_hash[password],
        rabbit_user            => $rabbit_hash[user],
        rabbit_ha_virtual_ip   => $::fuel_settings['management_vip'],
        auto_assign_floating_ip => $::fuel_settings['auto_assign_floating_ip'],
        glance_api_servers     => "${::fuel_settings['management_vip']}:9292",
        vncproxy_host          => $::fuel_settings['public_vip'],
        debug                  => $debug ? { 'true' => true, true => true, default=> false },
        verbose                => $verbose ? { 'true' => true, true => true, default=> false },
        cinder_volume_group    => "cinder",
        vnc_enabled            => true,
        manage_volumes         => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
        nova_user_password     => $nova_hash[user_password],
        cache_server_ip        => $controller_nodes,
        service_endpoint       => $::fuel_settings['management_vip'],
        cinder                 => true,
        cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        db_host                => $::fuel_settings['management_vip'],
        quantum                => $::use_quantum,
        quantum_host           => $quantum_host,
        quantum_sql_connection => $quantum_sql_connection,
        quantum_user_password  => $quantum_hash[user_password],
        tenant_network_type    => $tenant_network_type,
        segment_range          => $segment_range,
        use_syslog             => true,
        syslog_log_level       => $syslog_log_level,
        syslog_log_facility    => $syslog_log_facility_nova,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        nova_rate_limits       => $nova_rate_limits,
        state_path             => $nova_hash[state_path],
      }

        if defined(Class['ceph']){
          Class['openstack::compute'] -> Class['ceph']
        }

#      class { "::rsyslog::client":
#        log_local => true,
#        log_auth_local => true,
#        rservers => $rservers,
#      }
      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }
    }

    "cinder" : {
      include keystone::python
      package { 'python-amqp':
        ensure => present
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${::fuel_settings['management_vip']}/cinder?charset=utf8",
        glance_api_servers   => "${::fuel_settings['management_vip']}:9292",
        queue_provider       => $::queue_provider,
        qpid_password        => $rabbit_hash[password],
        qpid_user            => $rabbit_hash[user],
        qpid_nodes           => [$::fuel_settings['management_vip']],
        rabbit_password      => $rabbit_hash[password],
        rabbit_host          => false,
        rabbit_nodes         => $::fuel_settings['management_vip'],
        volume_group         => 'cinder',
        manage_volumes       => true,
        enabled              => true,
        auth_host            => $::fuel_settings['management_vip'],
        iscsi_bind_host      => $storage_address,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $syslog_log_facility_cinder,
        syslog_log_level     => $syslog_log_level,
        debug                => $debug ? { 'true' => true, true => true, default=> false },
        verbose              => $verbose ? { 'true' => true, true => true, default=> false },
        use_syslog           => true,
      }
#      class { "::rsyslog::client":
#        log_local => true,
#        log_auth_local => true,
#        rservers => $rservers,
#      }
    }
    "ceph-osd" : {
      #Class Ceph is already defined so it will do it's thing.
      notify {"ceph_osd: ${::ceph::osd_devices}": }
      notify {"osd_devices:  ${::osd_devices_list}": }
    }
  
  }
}
