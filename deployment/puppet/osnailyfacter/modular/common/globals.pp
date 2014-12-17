$nodes_hash                     = hiera('nodes', {})
$ceilometer_hash                = hiera('ceilometer', {})
$storage_hash                   = hiera('storage', {})
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$heat_hash                      = hiera('heat', {})
$vcenter_hash                   = hiera('vcenter', {})
$nova_hash                      = hiera('nova', {})
$mysql_hash                     = hiera('mysql', {})
$rabbit_hash                    = hiera('rabbit', {})
$glance_hash                    = hiera('glance', {})
$keystone_hash                  = hiera('keystone', {})
$swift_hash                     = hiera('swift', {})
$cinder_hash                    = hiera('cinder', {})
$access_hash                    = hiera('access', {})

$role                           = hiera('role')
$cinder_nodes_array             = hiera('cinder_nodes', [])
$dns_nameservers                = hiera('dns_nameservers')
$use_neutron                    = hiera('quantum')
$network_scheme                 = hiera('network_scheme')
$disable_offload                = hiera('disable_offload')
$verbose                        = true
$debug                          = hiera('debug', false)
$use_monit                      = false
$master_ip                      = hiera('master_ip')
$management_network_range       = hiera('management_network_range')

# syslog
$use_syslog                     = hiera('use_syslog', true)
$syslog_log_facility_glance     = 'LOG_LOCAL2'
$syslog_log_facility_cinder     = 'LOG_LOCAL3'
$syslog_log_facility_neutron    = 'LOG_LOCAL4'
$syslog_log_facility_nova       = 'LOG_LOCAL6'
$syslog_log_facility_keystone   = 'LOG_LOCAL7'
$syslog_log_facility_murano     = 'LOG_LOCAL0'
$syslog_log_facility_heat       = 'LOG_LOCAL0'
$syslog_log_facility_sahara     = 'LOG_LOCAL0'
$syslog_log_facility_ceilometer = 'LOG_LOCAL0'
$syslog_log_facility_ceph       = 'LOG_LOCAL0'

$nova_report_interval           = '60'
$nova_service_down_time         = '180'

$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

$nova_rate_limits = {
  'POST' => 100000,
  'POST_SERVERS' => 100000,
  'PUT' => 1000,
  'GET' => 100000,
  'DELETE' => 100000
}

$cinder_rate_limits = {
  'POST' => 100000,
  'POST_SERVERS' => 100000,
  'PUT' => 100000,
  'GET' => 100000,
  'DELETE' => 100000
}

$node                 = filter_nodes($nodes_hash, 'name', hostname)
if empty($node) {
  fail("Node hostname is not defined in the hash structure")
}
$default_gateway      = $node[0]['default_gateway']

prepare_network_config($network_scheme)
if $use_neutron {
  $internal_int     = get_network_role_property('management', 'interface')
  $internal_address = get_network_role_property('management', 'ipaddr')
  $internal_netmask = get_network_role_property('management', 'netmask')
  $public_int       = get_network_role_property('ex', 'interface')
  if $public_int {
    $public_address = get_network_role_property('ex', 'ipaddr')
    $public_netmask = get_network_role_property('ex', 'netmask')
  }
  $storage_address  = get_network_role_property('storage', 'ipaddr')
  $storage_netmask  = get_network_role_property('storage', 'netmask')

  $novanetwork_params        = {}
  $neutron_config            = hiera('quantum_settings')
  $network_provider          = 'neutron'
  $neutron_db_password       = $neutron_config['database']['passwd']
  $neutron_user_password     = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                  = $neutron_config['L2']['base_mac']

  $nsx_config = hiera('nsx_plugin')
  if $nsx_plugin['metadata']['enabled'] {
    $use_vmware_nsx     = true
    $neutron_nsx_config = $nsx_plugin
  }

} else {
  $internal_address = $node[0]['internal_address']
  $internal_netmask = $node[0]['internal_netmask']
  $public_address   = $node[0]['public_address']
  $public_netmask   = $node[0]['public_netmask']
  $storage_address  = $node[0]['storage_address']
  $storage_netmask  = $node[0]['storage_netmask']
  $public_br        = $node[0]['public_br']
  $internal_br      = $node[0]['internal_br']
  $public_int       = hiera('public_interface')
  $internal_int     = hiera('management_interface')

  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
  $network_size       = $novanetwork_params['network_size']
  $num_networks       = $novanetwork_params['num_networks']
  $vlan_start         = $novanetwork_params['vlan_start']
  $network_provider   = 'nova'
  $network_config = {
    'vlan_start'     => $vlan_start,
  }
  $network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"
}

# mellanox
$neutron_mellanox = hiera('neutron_mellanox')
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

case operatingsystem {
  'redhat' : {
    $queue_provider = 'qpid'
    $custom_mysql_setup_class = 'pacemaker_mysql'
  }
  default: {
    $queue_provider='rabbitmq'
    $custom_mysql_setup_class='galera'
  }
}
validate_re($queue_provider,  'rabbitmq|qpid')

# ceph
$ceph_nodes = filter_nodes($nodes_hash, 'role', 'ceph-osd')
if !empty($ceph_node) or
   $storage_hash['volumes_ceph'] or
   $storage_hash['images_ceph'] or
   $storage_hash['objects_ceph'] {
  $use_ceph = true
} else {
  $use_ceph = false
}

$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public = $controller[0]['public_address']
$roles = node_roles($nodes_hash, fuel_settings['uid'])

# AMQP client configuration
$amqp_port = '5672'
$amqp_hosts = "${controller_node_address}:${amqp_port}"
$rabbit_ha_queues = false

# RabbitMQ server configuration
$rabbitmq_bind_ip_address = 'UNSET'                 # bind RabbitMQ to 0.0.0.0
$rabbitmq_bind_port = $amqp_port
$rabbitmq_cluster_nodes = [$controller[0]['name']]  # has to be hostnames

# SQLAlchemy backend configuration
$max_pool_size = min(processorcount * 5 + 0, 30 + 0)
$max_overflow = min(processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

$nova_db_password = $nova_hash['db_password']
$cinder_iscsi_bind_addr = storage_address
$sql_connection = "mysql://nova:${nova_db_password}@${controller_node_address}/nova?read_timeout=60"
$mirror_type = 'external'
$multi_host = true

# Determine who should get the volume service
if (member($roles, 'cinder') and $storage_hash['volumes_lvm']) {
  $manage_volumes = 'iscsi'
} elsif (member($roles, 'cinder') and $storage_hash['volumes_vmdk']) {
  $manage_volumes = 'vmdk'
} elsif ($storage_hash['volumes_ceph']) {
  $manage_volumes = 'ceph'
} else {
  $manage_volumes = false
}

#Determine who should be the default backend

if ($storage_hash['images_ceph']) {
  $glance_backend = 'ceph'
  $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
} else {
  $glance_backend = 'file'
  $glance_known_stores = false
}

