class osnailyfacter::cluster_simple {


if $quantum == 'true'
{
  $quantum_hash   = parsejson($::quantum_access)
  $quantum_params = parsejson($::quantum_parameters)
  $novanetwork_params  = {}

}
else
{
  $quantum_hash = {}
  $quantum_params = {}
  $novanetwork_params  = parsejson($::novanetwork_parameters)
}

if $cinder_nodes {
   $cinder_nodes_array   = parsejson($::cinder_nodes)
}
else {
  $cinder_nodes_array = []
}



$nova_hash            = parsejson($::nova)
$mysql_hash           = parsejson($::mysql)
$rabbit_hash          = parsejson($::rabbit)
$glance_hash          = parsejson($::glance)
$keystone_hash        = parsejson($::keystone)
$swift_hash           = parsejson($::swift)
$cinder_hash          = parsejson($::cinder)
$access_hash          = parsejson($::access)
$nodes_hash           = parsejson($::nodes)
$vlan_start           = $novanetwork_params['vlan_start']
$network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"
$network_size         = $novanetwork_params['network_size']
$num_networks         = $novanetwork_params['num_networks']
$tenant_network_type  = $quantum_params['tenant_network_type']
$segment_range        = $quantum_params['segment_range']

if !$rabbit_hash[user]
{
  $rabbit_hash[user] = 'nova'
}
$rabbit_user          = $rabbit_hash['user']



if $auto_assign_floating_ip == 'true' {
  $bool_auto_assign_floating_ip = true
} else {
  $bool_auto_assign_floating_ip = false
}

if $quantum {
   $floating_hash =  $::floating_network_range
}
else {
  $floating_hash = {}
  $floating_ips_range = parsejson($floating_network_range)
}

$controller = filter_nodes($nodes_hash,'role','controller')

$controller_node_address = $controller[0]['internal_address']
$controller_node_public = $controller[0]['public_address']


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


$cinder_iscsi_bind_addr = $::storage_address

# do not edit the below line
validate_re($::queue_provider,  'rabbitmq|qpid')

$network_config = {
  'vlan_start'     => $vlan_start,
}
$sql_connection           = "mysql://nova:${nova_hash[db_password]}@${controller_node_address}/nova"
$mirror_type = 'external'
$multi_host              = true
Exec { logoutput => true }

$quantum_host            = $controller_node_address
$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"
$quantum_metadata_proxy_shared_secret = $quantum_params['metadata_proxy_shared_secret']
$quantum_gre_bind_addr = $::internal_address

if !$verbose
{
 $verbose = 'false'
}

if !$debug
{
 $debug = 'false'
}

#TODO: awoodward fix static $use_ceph
$use_ceph = false
if ($use_ceph) {
  $primary_mons   = $controller
  $primary_mon    = $controller[0]['name']
  $glance_backend = 'ceph'
  class {'ceph': 
    primary_mon  => $primary_mon,
    cluster_node_address => $controller_node_address,
  }
} else {
  $glance_backend = 'file'
}

  case $role {
    "controller" : {
      include osnailyfacter::test_controller

      class {'osnailyfacter::apache_api_proxy':}
      class { 'openstack::controller':
        admin_address           => $controller_node_address,
        public_address          => $controller_node_public,
        public_interface        => $public_int,
        private_interface       => $fixed_interface,
        internal_address        => $controller_node_address,
        floating_range          => $quantum ? { 'true' =>$floating_hash, default=>false},
        fixed_range             => $fixed_network_range,
        multi_host              => $multi_host,
        network_manager         => $network_manager,
        num_networks            => $num_networks,
        network_size            => $network_size,
        network_config          => $network_config,
        debug                   => $debug ? { 'true' => true, true => true, default=> false },
        verbose                 => $verbose ? { 'true' => true, true => true, default=> false },
        auto_assign_floating_ip => $bool_auto_assign_floating_ip,
        mysql_root_password     => $mysql_hash[root_password],
        admin_email             => $access_hash[email],
        admin_user              => $access_hash[user],
        admin_password          => $access_hash[password],
        keystone_db_password    => $keystone_hash[db_password],
        keystone_admin_token    => $keystone_hash[admin_token],
        keystone_admin_tenant   => $access_hash[tenant],
        glance_db_password      => $glance_hash[db_password],
        glance_user_password    => $glance_hash[user_password],
        glance_backend          => $glance_backend,
        nova_db_password        => $nova_hash[db_password],
        nova_user_password      => $nova_hash[user_password],
        nova_rate_limits        => $nova_rate_limits,
        queue_provider          => $::queue_provider,
        rabbit_password         => $rabbit_hash[password],
        rabbit_user             => $rabbit_hash[user],
        qpid_password           => $rabbit_hash[password],
        qpid_user               => $rabbit_hash[user],
        export_resources        => false,
        quantum                 => $quantum,
        quantum_user_password         => $quantum_hash[user_password],
        quantum_db_password           => $quantum_hash[db_password],
        quantum_network_node          => $quantum,
        quantum_netnode_on_cnt        => true,
        quantum_gre_bind_addr         => $quantum_gre_bind_addr,
        quantum_external_ipinfo       => $external_ipinfo,
        tenant_network_type           => $tenant_network_type,
        segment_range                 => $segment_range,
        cinder                  => true,
        cinder_user_password    => $cinder_hash[user_password],
        cinder_db_password      => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
        use_syslog              => true,
        syslog_log_level        => $syslog_log_level,
        syslog_log_facility_glance   => $syslog_log_facility_glance,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_nova => $syslog_log_facility_nova,
        syslog_log_facility_keystone => $syslog_log_facility_keystone,
        cinder_rate_limits      => $cinder_rate_limits,
        horizon_use_ssl         => $horizon_use_ssl,
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $start_guests_on_host_boot }
      nova_config { 'DEFAULT/use_cow_images': value => $use_cow_images }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $compute_scheduler_driver }
 if $::quantum {
    class { '::openstack::quantum_router':
      db_host               => $controller_node_address,
      service_endpoint      => $controller_node_address,
      auth_host             => $controller_node_address,
      nova_api_vip          => $controller_node_address,
      internal_address      => $internal_address,
      public_interface      => $public_int,
      private_interface     => $fixed_interface,
      floating_range        => $floating_hash,
      fixed_range           => $fixed_network_range,
      create_networks       => $create_networks,
      debug                 => $debug ? { 'true' => true, true => true, default=> false },
      verbose               => $verbose ? { 'true' => true, true => true, default=> false },
      queue_provider        => $queue_provider,
      rabbit_password       => $rabbit_hash[password],
      rabbit_user           => $rabbit_hash[user],
      rabbit_ha_virtual_ip  => $controller_node_address,
      rabbit_nodes          => [$controller_node_address],
      qpid_password         => $rabbit_hash[password],
      qpid_user             => $rabbit_hash[user],
      qpid_nodes            => [$controller_node_address],
      quantum               => $quantum,
      quantum_user_password => $quantum_hash[user_password],
      quantum_db_password   => $quantum_hash[db_password],
      quantum_gre_bind_addr => $quantum_gre_bind_addr,
      quantum_network_node  => true,
      quantum_netnode_on_cnt=> $quantum,
      tenant_network_type   => $tenant_network_type,
      segment_range         => $segment_range,
      external_ipinfo       => $external_ipinfo,
      api_bind_address      => $internal_address,
      use_syslog            => $use_syslog,
      syslog_log_level      => $syslog_log_level,
      syslog_log_facility   => $syslog_log_facility_quantum,
    }
  }


      class { 'openstack::auth_file':
        admin_user           => $access_hash[user],
        admin_password       => $access_hash[password],
        keystone_admin_token => $keystone_hash[admin_token],
        admin_tenant         => $access_hash[tenant],
        controller_node      => $controller_node_address,
      }


      # glance_image is currently broken in fuel

      # glance_image {'testvm':
      #   ensure           => present,
      #   name             => "Cirros testvm",
      #   is_public        => 'yes',
      #   container_format => 'ovf',
      #   disk_format      => 'raw',
      #   source           => '/opt/vm/cirros-0.3.0-x86_64-disk.img',
      #   require          => Class[glance::api],
      # }
#TODO: fix this so it dosn't break ceph
      class { 'openstack::img::cirros':
        os_username               => shellescape($access_hash[user]),
        os_password               => shellescape($access_hash[password]),
        os_tenant_name            => shellescape($access_hash[tenant]),
        img_name                  => "TestVM",
        stage                     => 'glance-image',
      }
      Class[glance::api]        -> Class[openstack::img::cirros]

      if !$quantum {
        nova_floating_range{ $floating_ips_range:
          ensure          => 'present',
          pool            => 'nova',
          username        => $access_hash[user],
          api_key         => $access_hash[password],
          auth_method     => 'password',
          auth_url        => "http://${controller_node_address}:5000/v2.0/",
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
        public_interface       => $public_int,
        private_interface      => $fixed_interface,
        internal_address       => $internal_address,
        libvirt_type           => $libvirt_type,
        fixed_range            => $fixed_network_range,
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => $sql_connection,
        nova_user_password     => $nova_hash[user_password],
        queue_provider         => $::queue_provider,
        rabbit_nodes           => [$controller_node_address],
        rabbit_password        => $rabbit_hash[password],
        rabbit_user            => $rabbit_user,
        auto_assign_floating_ip => $bool_auto_assign_floating_ip,
        qpid_nodes             => [$controller_node_address],
        qpid_password          => $rabbit_hash[password],
        qpid_user              => $rabbit_user,
        glance_api_servers     => "${controller_node_address}:9292",
        vncproxy_host          => $controller_node_public,
        vnc_enabled            => true,
        quantum                => $quantum,
        quantum_host           => $quantum_host,
        quantum_sql_connection => $quantum_sql_connection,
        quantum_user_password  => $quantum_hash[user_password],
        tenant_network_type    => $tenant_network_type,
        service_endpoint       => $controller_node_address,
        cinder                 => true,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
        db_host                => $controller_node_address,
        debug                  => $debug ? { 'true' => true, true => true, default=> false },
        verbose                => $verbose ? { 'true' => true, true => true, default=> false },
        use_syslog             => true,
        syslog_log_level       => $syslog_log_level,
	syslog_log_facility    => $syslog_log_facility_nova,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        state_path             => $nova_hash[state_path],
        nova_rate_limits       => $nova_rate_limits,
        cinder_rate_limits     => $cinder_rate_limits
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $start_guests_on_host_boot }
      nova_config { 'DEFAULT/use_cow_images': value => $use_cow_images }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $compute_scheduler_driver }

      if defined(Class['ceph']){
        Class['openstack::compute'] -> Class['ceph']
      }
    }

    "cinder" : {
      include keystone::python
      package { 'python-amqp':
        ensure => present
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${controller_node_address}/cinder?charset=utf8",
        glance_api_servers   => "${controller_node_address}:9292",
        queue_provider       => $::queue_provider,
        rabbit_password      => $rabbit_hash[password],
        rabbit_host          => false,
        rabbit_nodes         => [$controller_node_address],
        qpid_password        => $rabbit_hash[password],
        qpid_user            => $rabbit_hash[user],
        qpid_nodes           => [$controller_node_address],
        volume_group         => 'cinder',
        manage_volumes       => true,
        enabled              => true,
        auth_host            => $controller_node_address,
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $syslog_log_facility_cinder,
        syslog_log_level     => $syslog_log_level,
        debug                => $debug ? { 'true' => true, true => true, default=> false },
        verbose              => $verbose ? { 'true' => true, true => true, default=> false },
        use_syslog           => true,
      }
   }
   "ceph-osd" : {
     #Nothing needs to be done Class Ceph is already defined
     notify {"ceph-osd: ${::ceph::osd_devices}": }
     notify {"osd_devices:  ${::osd_devices_list}": }
   }
  }
}
