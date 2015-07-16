notice('MODULAR: globals.pp')

$network_scheme = hiera_hash('network_scheme', {})
if empty($network_scheme) {
  fail("Network_scheme not given in the astute.yaml")
}
$network_metadata = hiera_hash('network_metadata', {})
if empty($network_metadata) {
  fail("Network_metadata not given in the astute.yaml")
}

$node_name = regsubst(hiera('fqdn', $::hostname), '\..*$', '')
$node = $network_metadata['nodes'][$node_name]
if empty($node) {
  fail("Node hostname is not defined in the astute.yaml")
}

prepare_network_config($network_scheme)

$nodes_hash                     = hiera('nodes', {})  #todo(sv): remove using NODES list!
$deployment_mode                = hiera('deployment_mode', 'ha_compact')
$roles                          = $node['node_roles']
$storage_hash                   = hiera('storage', {})
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$heat_hash                      = hiera_hash('heat', {})
$vcenter_hash                   = hiera('vcenter', {})
$nova_hash                      = hiera_hash('nova', {})
$mysql_hash                     = hiera('mysql', {})
$rabbit_hash                    = hiera('rabbit', {})
$glance_hash                    = hiera_hash('glance', {})
$keystone_hash                  = hiera_hash('keystone', {})
$swift_hash                     = hiera('swift', {})
$cinder_hash                    = hiera_hash('cinder', {})
$ceilometer_hash                = hiera('ceilometer',{})
$access_hash                    = hiera_hash('access', {})
$mp_hash                        = hiera('mp', {})

$node_role                      = hiera('role')
$dns_nameservers                = hiera('dns_nameservers', [])
$use_ceilometer                 = $ceilometer_hash['enabled']
$use_neutron                    = hiera('quantum', false)
$verbose                        = true
$debug                          = hiera('debug', false)
$use_monit                      = false
$master_ip                      = hiera('master_ip')
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

$default_gateway = get_default_gateways()

$internal_int                  = get_network_role_property('management', 'interface')
$public_int                    = get_network_role_property('ex', 'interface')
$internal_address              = get_network_role_property('management', 'ipaddr')
$internal_netmask              = get_network_role_property('management', 'netmask')
$public_address                = get_network_role_property('ex', 'ipaddr')
$public_netmask                = get_network_role_property('ex', 'netmask')
$storage_address               = get_network_role_property('storage', 'ipaddr')
$storage_netmask               = get_network_role_property('storage', 'netmask')
#todo(sv): It's a workaround. After merge some part to Nailgun and change CI ISO we should use just $network_metadata['vips']['VIP_NAME']['ipaddr']
#todo(sv): Also some VIPs was renamed
if is_hash($network_metadata['vips']['public']) {
  $public_vip                  = $network_metadata['vips']['public']['ipaddr']
} else {
  $public_vip                  = $network_metadata['vips']['public_vip']
}
if is_hash($network_metadata['vips']['management']) {
  $management_vip                  = $network_metadata['vips']['management']['ipaddr']
} else {
  $management_vip                  = $network_metadata['vips']['management_vip']
}
if is_hash($network_metadata['vips']['database']) {
  $database_vip                = $network_metadata['vips']['database']['ipaddr']
} else {
  $database_vip                = pick($network_metadata['vips']['database'], $management_vip)
}
if is_hash($network_metadata['vips']['vrouter_pub']) {
  $public_vrouter_vip          = $network_metadata['vips']['vrouter_pub']['ipaddr']
} else {
  $public_vrouter_vip          = $network_metadata['vips']['public_vrouter_vip']
}
if is_hash($network_metadata['vips']['vrouter']) {
  $management_vrouter_vip      = $network_metadata['vips']['vrouter']['ipaddr']
} else {
  $management_vrouter_vip      = $network_metadata['vips']['management_vrouter_vip']
}
if is_hash($network_metadata['vips']['service_endpoint']) {
  $service_endpoint            = $network_metadata['vips']['service_endpoint']['ipaddr']
} else {
  $service_endpoint            = pick($network_metadata['vips']['service_endpoint'],  $management_vip)
}
#todo(sv): end of workaround

if $use_neutron {
  $novanetwork_params            = {}
  $neutron_config                = hiera_hash('quantum_settings')
  $network_provider              = 'neutron'
  $neutron_db_password           = $neutron_config['database']['passwd']
  $neutron_user_password         = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                      = $neutron_config['L2']['base_mac']
  $management_network_range      = get_network_role_property('mgmt/vip', 'network')
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
  $network_manager          = "nova.network.manager.${novanetwork_params['network_manager']}"
  $management_network_range = hiera('management_network_range')
}

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
$controller_node_public        = $public_vip
$controller_node_address       = $management_vip
$mountpoints                   = filter_hash($mp_hash,'point')

$controllers_hash = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])

# AMQP configuration
$queue_provider   = hiera('queue_provider','rabbitmq')
$rabbit_ha_queues = true
if !$rabbit_hash['user'] {
  $rabbit_hash['user'] = 'nova'
}

$amqp_port  = hiera('amqp_ports', '5673')
if hiera('amqp_hosts', false) {
  # using pre-defined in astute.yaml RabbitMQ servers
  $amqp_hosts = hiera('amqp_hosts')
} else {
  # using RabbitMQ servers on controllers
  # todo(sv): switch from 'controller' nodes to 'rmq' nodes as soon as it was implemented as additional node-role
  $controllers_with_amqp_server = get_node_to_ipaddr_map_by_network_role($controllers_hash, 'mgmt/messaging')
  $amqp_nodes = ipsort(values($controllers_with_amqp_server))
  # amqp_hosts() randomize order of RMQ endpoints and put local one first
  $amqp_hosts = amqp_hosts($amqp_nodes, $amqp_port, get_network_role_property('mgmt/messaging', 'ipaddr'))
}

# MySQL and SQLAlchemy backend configuration
$custom_mysql_setup_class = hiera('custom_mysql_setup_class', 'galera')
$max_pool_size            = hiera('max_pool_size', min($::processorcount * 5 + 0, 30 + 0))
$max_overflow             = hiera('max_overflow', min($::processorcount * 5 + 0, 60 + 0))
$max_retries              = hiera('max_retries', '-1')
$idle_timeout             = hiera('idle_timeout','3600')
$nova_db_password         = $nova_hash['db_password']
$sql_connection           = "mysql://nova:${nova_db_password}@${database_vip}/nova?read_timeout = 6 0"
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

# Define memcached-related variables:
# todo(sv): change to 'memcache' as soon as this node role was ready
$memcache_servers = values(get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']), 'mgmt/memcache'))

# Define cinder-related variables
# todo: use special node-roles instead controllers in the future
$cinder_nodes           = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])

# Define swift-related variables
# todo(sv): use special node-roles instead controllers in the future
$swift_master_role   = 'primary-controller'
$swift_nodes         = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])
$swift_proxies       = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])
$swift_proxy_caches  = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']) # memcache for swift
$is_primary_swift_proxy = $primary_controller

# save all these global variables into hiera yaml file for later use
# by other manifests with hiera function
file { '/etc/hiera/globals.yaml' :
  ensure  => 'present',
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => template('osnailyfacter/globals_yaml.erb')
}
