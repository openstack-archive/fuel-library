notice('MODULAR: globals.pp')
#FIXME(bogdando) make all evaluations/hardcode to come from a hiera
# For example, assume it is already calculated and use just:
#   $roles=hiera('roles')
# instead of:
#   $roles = node_roles($nodes_hash, hiera('uid'))

$fuel_settings = parseyaml($astute_settings_yaml)

$uid                            = hiera('uid')
$nodes_hash                     = hiera('nodes', {})
$deployment_mode                = hiera('deployment_mode', 'ha_compact')
$roles                          = hiera('roles', node_roles($nodes_hash, $uid))
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
$ceilometer_hash                = hiera('ceilometer',{})
$access_hash                    = hiera('access', {})
$mp_hash                        = hiera('mp', {})

$node_role                      = hiera('role')
$cinder_nodes_array             = hiera('cinder_nodes', [])
$dns_nameservers                = hiera('dns_nameservers', [])
$use_ceilometer                 = $ceilometer_hash['enabled']
$use_neutron                    = hiera('quantum', false)
$network_scheme                 = hiera('network_scheme', {})
$verbose                        = true
$debug                          = hiera('debug', false)
$use_monit                      = false
$master_ip                      = hiera('master_ip')
$management_network_range       = hiera('management_network_range')

$use_syslog                     = hiera('use_syslog', true)
$syslog_log_facility_glance     = hiera('syslog_log_facility_glance', 'LOG_LOCAL2')
$syslog_log_facility_cinder     = hiera('syslog_log_facility_cinder', 'LOG_LOCAL3')
$syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
$syslog_log_facility_nova       = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$syslog_log_facility_keystone   = hiera('syslog_log_facility_keystone', 'LOG_LOCAL7')
$syslog_log_facility_murano     = hiera('syslog_log_facility_murano', 'LOG_LOCAL0')
$syslog_log_facility_heat       = hiera('syslog_log_facility_heat','LOG_LOCAL0')
$syslog_log_facility_sahara     = hiera('syslog_log_facility_sahara','LOG_LOCAL0')
$syslog_log_facility_ceilometer = hiera('syslog_log_facility_ceilometer','LOG_LOCAL0')
$syslog_log_facility_ceph       = hiera('syslog_log_facility_ceph','LOG_LOCAL0')

$nova_report_interval           = hiera('nova_report_interval', 60)
$nova_service_down_time         = hiera('nova_service_down_time', 180)
$apache_ports                   = hiera_array('apache_ports', ['80', '8888'])

$openstack_version = hiera('openstack_version',
  {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
  }
)

$nova_rate_limits = hiera('nova_rate_limits',
  {
    'POST'         => 100000,
    'POST_SERVERS' => 100000,
    'PUT'          => 1000,
    'GET'          => 100000,
    'DELETE'       => 100000
  }
)

$cinder_rate_limits = hiera('cinder_rate_limits',
  {
    'POST'         => 100000,
    'POST_SERVERS' => 100000,
    'PUT'          => 100000,
    'GET'          => 100000,
    'DELETE'       => 100000
  }
)

$node = hiera('node', filter_nodes($nodes_hash, 'uid', $uid))
if empty($node) {
  fail("Node hostname is not defined in the hash structure")
}
$default_gateway = hiera('default_gateway', $node[0]['default_gateway'])

prepare_network_config($network_scheme)
$internal_int                  = get_network_role_property('management', 'interface')
$public_int                    = get_network_role_property('ex', 'interface')
$internal_address              = get_network_role_property('management', 'ipaddr')
$internal_netmask              = get_network_role_property('management', 'netmask')
$public_address                = get_network_role_property('ex', 'ipaddr')
$public_netmask                = get_network_role_property('ex', 'netmask')
$storage_address               = get_network_role_property('storage', 'ipaddr')
$storage_netmask               = get_network_role_property('storage', 'netmask')

if $use_neutron {
  $novanetwork_params            = {}
  $neutron_config                = hiera('quantum_settings')
  $network_provider              = 'neutron'
  $neutron_db_password           = $neutron_config['database']['passwd']
  $neutron_user_password         = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                      = $neutron_config['L2']['base_mac']
} else {
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
  $network_size       = $novanetwork_params['network_size']
  $num_networks       = $novanetwork_params['num_networks']
  $network_provider   = 'nova'
  if ( $novanetwork_params['network_manager'] == 'FlatDHCPManager') {
    $private_int                  = get_network_role_property('novanetwork/fixed', 'interface')
  } else {
    $private_int                  = get_network_role_property('novanetwork/vlan', 'interface')
    $vlan_start         = $novanetwork_params['vlan_start']
    $network_config     = {
      'vlan_start'      => $vlan_start,
    }
  }
  $network_manager    = "nova.network.manager.${novanetwork_params['network_manager']}"
}

if $deployment_mode == 'ha_compact' {
  $primary_controller            = $node_role ? { 'primary-controller' => true, default =>false }
  $primary_controller_nodes      = filter_nodes($nodes_hash,'role','primary-controller')
  $controllers                   = concat($primary_controller_nodes,
                                          filter_nodes($nodes_hash,'role','controller')
  )
  $controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
  $controller_public_addresses   = nodes_to_hash($controllers,'name','public_address')
  $controller_storage_addresses  = nodes_to_hash($controllers,'name','storage_address')
  $controller_hostnames          = keys($controller_internal_addresses)
  $controller_nodes              = ipsort(values($controller_internal_addresses))
  $controller_node_public        = hiera('public_vip')
  $controller_node_address       = hiera('management_vip')
  $mountpoints                   = filter_hash($mp_hash,'point')
} else {
  # simple multinode
  $controller              = filter_nodes($nodes_hash, 'role', 'controller')
  $controller_node_address = $controller[0]['internal_address']
  $controller_node_public  = $controller[0]['public_address']
}

# AMQP configuration
$queue_provider = hiera('queue_provider','rabbitmq')

if !$rabbit_hash['user'] {
$rabbit_hash['user'] = 'nova'
}

if $deployment_mode == 'ha_compact' {
  $amqp_port              = '5673'
  $amqp_hosts             = amqp_hosts($controller_nodes, $amqp_port, $internal_address)
  $rabbit_ha_queues       = true
  $rabbitmq_cluster_nodes = $controller_hostnames
} else {
  # simple multinode (deprecated)
  $amqp_port              = '5672'
  $amqp_hosts             = amqp_hosts($controller_node_address, $amqp_port)
  $rabbitmq_cluster_nodes = [ $controller[0]['name'] ]
  $rabbit_ha_queues       = false
}

# MySQL and SQLAlchemy backend configuration
$custom_mysql_setup_class = hiera('custom_mysql_setup_class', 'galera')
$max_pool_size            = hiera('max_pool_size', min($::processorcount * 5 + 0, 30 + 0))
$max_overflow             = hiera('max_overflow', min($::processorcount * 5 + 0, 60 + 0))
$max_retries              = hiera('max_retries', '-1')
$idle_timeout             = hiera('idle_timeout','3600')
$nova_db_password         = $nova_hash['db_password']
$cinder_iscsi_bind_addr   = $storage_address
$sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_address}/nova?read_timeout = 6 0"
$mirror_type              = hiera('mirror_type', 'external')
$multi_host               = hiera('multi_host', true)

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

# save all these global variables into hiera yaml file for later use
# by other manifests with hiera function
file { '/etc/hiera/globals.yaml' :
  ensure  => 'present',
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => template('osnailyfacter/globals_yaml.erb')
}
