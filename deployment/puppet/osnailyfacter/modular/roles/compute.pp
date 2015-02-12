notice('MODULAR: compute.pp')

# Pulling hiera
$internal_int                   = hiera('internal_int')
$public_int                     = hiera('public_int', undef)
$public_vip                     = hiera('public_vip')
$management_vip                 = hiera('management_vip')
$internal_address               = hiera('internal_address')
$primary_controller             = hiera('primary_controller')
$storage_address                = hiera('storage_address')
$use_neutron                    = hiera('use_neutron')
$neutron_nsx_config             = hiera('nsx_plugin')
$cinder_nodes_array             = hiera('cinder_nodes', [])
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$heat_hash                      = hiera('heat', {})
$mp_hash                        = hiera('mp')
$verbose                        = true
$debug                          = hiera('debug', true)
$use_monit                      = false
$mongo_hash                     = hiera('mongo', {})
$auto_assign_floating_ip        = hiera('auto_assign_floating_ip', false)
$nodes_hash                     = hiera('nodes', {})
$storage_hash                   = hiera('storage', {})
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
$network_scheme                 = hiera('network_scheme', {})
$controllers                    = hiera('controllers')
$neutron_mellanox               = hiera('neutron_mellanox', false)
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
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
$nova_rate_limits               = hiera('nova_rate_limits')
$nova_report_interval           = hiera('nova_report_interval')
$nova_service_down_time         = hiera('nova_service_down_time')

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

$queue_provider='rabbitmq'
$custom_mysql_setup_class='galera'

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

if (!empty(filter_nodes(hiera('nodes'), 'role', 'ceph-osd')) or
  $storage_hash['volumes_ceph'] or
  $storage_hash['images_ceph'] or
  $storage_hash['objects_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}


if $use_neutron {
  include l23network::l2
  $novanetwork_params        = {}
  $neutron_config            = hiera('quantum_settings')
  $neutron_db_password       = $neutron_config['database']['passwd']
  $neutron_user_password     = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                  = $neutron_config['L2']['base_mac']
  if $neutron_nsx_config['metadata']['enabled'] {
    $use_vmware_nsx     = true
  }
} else {
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
}

if !$ceilometer_hash {
  $ceilometer_hash = {
    enabled => false,
    db_password => 'ceilometer',
    user_password => 'ceilometer',
    metering_secret => 'ceilometer',
  }
  $ext_mongo = false
} else {
  # External mongo integration
  if $mongo_hash['enabled'] {
    $ext_mongo_hash = hiera('external_mongo')
    $ceilometer_db_user = $ext_mongo_hash['mongo_user']
    $ceilometer_db_password = $ext_mongo_hash['mongo_password']
    $ceilometer_db_name = $ext_mongo_hash['mongo_db_name']
    $ext_mongo = true
  } else {
    $ceilometer_db_user = 'ceilometer'
    $ceilometer_db_password = $ceilometer_hash['db_password']
    $ceilometer_db_name = 'ceilometer'
    $ext_mongo = false
    $ext_mongo_hash = {}
  }
}


if $primary_controller {
  if ($mellanox_mode == 'ethernet') {
    $test_vm_pkg = 'cirros-testvm-mellanox'
  } else {
    $test_vm_pkg = 'cirros-testvm'
  }
  package { 'cirros-testvm' :
    ensure => 'installed',
    name   => $test_vm_pkg,
  }
}


if $ext_mongo {
  $mongo_hosts = $ext_mongo_hash['hosts_ip']
  if $ext_mongo_hash['mongo_replset'] {
    $mongo_replicaset = $ext_mongo_hash['mongo_replset']
  } else {
    $mongo_replicaset = undef
  }
} elsif $ceilometer_hash['enabled'] {
  $mongo_hosts = mongo_hosts($nodes_hash)
  if size(mongo_hosts($nodes_hash, 'array', 'mongo')) > 1 {
    $mongo_replicaset = 'ceilometer'
  } else {
    $mongo_replicaset = undef
  }
}

if !$rabbit_hash['user'] {
  $rabbit_hash['user'] = 'nova'
}

$floating_hash = {}

##CALCULATED PARAMETERS


##NO NEED TO CHANGE

$node = filter_nodes($nodes_hash, 'name', $::hostname)
if empty($node) {
  fail("Node $::hostname is not defined in the hash structure")
}

# get cidr netmasks for VIPs
$primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')
$vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
$vip_public_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])

if $use_neutron {
  $vip_mgmt_other_nets = join($network_scheme['endpoints']["$internal_int"]['other_nets'], ' ')
}


##TODO: simply parse nodes array
$controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
$controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
$controller_storage_addresses = nodes_to_hash($controllers,'name','storage_address')
$controller_hostnames = keys($controller_internal_addresses)
$controller_nodes = ipsort(values($controller_internal_addresses))
$controller_node_public  = $public_vip
$controller_node_address = $management_vip
$roles = node_roles($nodes_hash, hiera('uid'))
$mountpoints = filter_hash($mp_hash,'point')

# AMQP client configuration
if $internal_address in $controller_nodes {
  # prefer local MQ broker if it exists on this node
  $amqp_nodes = concat(['127.0.0.1'], fqdn_rotate(delete($controller_nodes, $internal_address)))
} else {
  $amqp_nodes = fqdn_rotate($controller_nodes)
}

$amqp_port = '5673'
$amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.join ',' %>")
$rabbit_ha_queues = true

# RabbitMQ server configuration
$rabbitmq_bind_ip_address = 'UNSET'              # bind RabbitMQ to 0.0.0.0
$rabbitmq_bind_port = $amqp_port
$rabbitmq_cluster_nodes = $controller_hostnames  # has to be hostnames

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

$cinder_iscsi_bind_addr = $storage_address

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
  $glance_backend = 'swift'
  $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
}

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

if ($use_swift) {
  if !hiera('swift_partition', false) {
    $swift_partition = '/var/lib/glance/node'
  }
  $swift_proxies            = $controllers
  $swift_local_net_ip       = $storage_address
  $master_swift_proxy_nodes = filter_nodes($nodes_hash,'role','primary-controller')
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
  #$master_hostname         = $master_swift_proxy_nodes[0]['name']
  $swift_loopback = false
  if $primary_controller {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }
} elsif ($storage_hash['objects_ceph']) {
  $rgw_servers = $controllers
}

# NOTE(bogdando) for controller nodes running Corosync with Pacemaker
#   we delegate all of the monitor functions to RA instead of monit.
if member($roles, 'controller') or member($roles, 'primary-controller') {
  $use_monit_real = false
} else {
  $use_monit_real = $use_monit
}

if $use_monit_real {
  # Configure service names for monit watchdogs and 'service' system path
  # FIXME(bogdando) replace service_path to systemd, once supported
  include nova::params
  include cinder::params
  include neutron::params
  include l23network::params
  $nova_compute_name   = $::nova::params::compute_service_name
  $nova_api_name       = $::nova::params::api_service_name
  $nova_network_name   = $::nova::params::network_service_name
  $cinder_volume_name  = $::cinder::params::volume_service
  $ovs_vswitchd_name   = $::l23network::params::ovs_service_name
  case $::osfamily {
    'RedHat' : {
       $service_path   = '/sbin/service'
    }
    'Debian' : {
      $service_path    = '/usr/sbin/service'
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}

#HARDCODED PARAMETERS
if hiera('use_vcenter', false) {
  $multi_host = false
} else {
  $multi_host = true
}

$mirror_type = 'external'
Exec { logoutput => true }

if $use_vmware_nsx {
  class { 'plugin_neutronnsx':
    neutron_config     => $neutron_config,
    neutron_nsx_config => $neutron_nsx_config,
    roles              => $roles,
  }
}


#################################################################
# we need to evaluate ceph here, because ceph notifies compute
# service in case we use ceph backend for ephemeral storage
if $use_ceph {
  $primary_mons   = $controllers
  $primary_mon    = $controllers[0]['name']

  if ($use_neutron) {
    prepare_network_config($network_scheme)
    $ceph_cluster_network = get_network_role_property('storage', 'cidr')
    $ceph_public_network  = get_network_role_property('management', 'cidr')
  } else {
    $ceph_cluster_network = hiera('storage_network_range')
    $ceph_public_network = hiera('management_network_range')
  }

  class {'ceph':
    primary_mon              => $primary_mon,
    mon_hosts                => nodes_with_roles($nodes_hash, ['primary-controller',
                                                 'controller', 'ceph-mon'], 'name'),
    mon_ip_addresses         => nodes_with_roles($nodes_hash, ['primary-controller',
                                                 'controller', 'ceph-mon'], 'internal_address'),
    cluster_node_address     => $controller_node_public,
    osd_pool_default_size    => $storage_hash['osd_pool_size'],
    osd_pool_default_pg_num  => $storage_hash['pg_num'],
    osd_pool_default_pgp_num => $storage_hash['pg_num'],
    use_rgw                  => $storage_hash['objects_ceph'],
    glance_backend           => $glance_backend,
    rgw_pub_ip               => $public_vip,
    rgw_adm_ip               => $management_vip,
    rgw_int_ip               => $management_vip,
    cluster_network          => $ceph_cluster_network,
    public_network           => $ceph_public_network,
    use_syslog               => $use_syslog,
    syslog_log_level         => $syslog_log_level,
    syslog_log_facility      => $syslog_log_facility_ceph,
    rgw_keystone_admin_token => $keystone_hash['admin_token'],
    ephemeral_ceph           => $storage_hash['ephemeral_ceph']
  }
  Class['openstack::compute'] -> Class['ceph']
}
#################################################################
include osnailyfacter::test_compute

if ($::mellanox_mode == 'ethernet') {
  $net04_physnet = $neutron_config['predefined_networks']['net04']['L2']['physnet']
  class { 'mellanox_openstack::compute':
    physnet => $net04_physnet,
    physifc => $neutron_mellanox['physical_port'],
  }
}

class { 'openstack::compute':
  public_interface            => $public_int ? { undef=>'', default=>$public_int},
  private_interface              => $::use_neutron ? { true=>false, default=>hiera('private_int')},
  internal_address            => $internal_address,
  libvirt_type                => hiera('libvirt_type'),
  fixed_range                 => $use_neutron ? { true=>false, default=>hiera('fixed_network_range')},
  network_manager             => hiera('network_manager'),
  network_config              => hiera('network_config', {}),
  multi_host                  => $multi_host,
  sql_connection              => "mysql://nova:${nova_hash[db_password]}@${management_vip}/nova?read_timeout=60",
  queue_provider              => $queue_provider,
  amqp_hosts                  => $amqp_hosts,
  amqp_user                   => $rabbit_hash['user'],
  amqp_password               => $rabbit_hash['password'],
  rabbit_ha_queues            => $rabbit_ha_queues,
  auto_assign_floating_ip     => $auto_assign_floating_ip,
  glance_api_servers          => "${management_vip}:9292",
  vncproxy_host               => $public_vip,
  vncserver_listen            => '0.0.0.0',
  debug                       => $debug,
  verbose                     => $verbose,
  cinder_volume_group         => "cinder",
  vnc_enabled                 => true,
  manage_volumes              => $manage_volumes,
  nova_user_password          => $nova_hash[user_password],
  cache_server_ip             => $controller_nodes,
  service_endpoint            => $management_vip,
  cinder                      => true,
  cinder_iscsi_bind_addr      => $cinder_iscsi_bind_addr,
  cinder_user_password        => $cinder_hash[user_password],
  cinder_db_password          => $cinder_hash[db_password],
  ceilometer                  => $ceilometer_hash[enabled],
  ceilometer_metering_secret  => $ceilometer_hash[metering_secret],
  ceilometer_user_password    => $ceilometer_hash[user_password],
  db_host                     => $management_vip,
  network_provider            => hiera('network_provider'),
  neutron_user_password       => $neutron_user_password,
  base_mac                    => $base_mac,

  use_syslog                  => $use_syslog,
  syslog_log_facility         => $syslog_log_facility_nova,
  syslog_log_facility_neutron => $syslog_log_facility_neutron,
  nova_rate_limits            => $nova_rate_limits,
  nova_report_interval        => $nova_report_interval,
  nova_service_down_time      => $nova_service_down_time,
  state_path                  => $nova_hash[state_path],
  neutron_settings           => $neutron_config,
  storage_hash               => $storage_hash,
}

#TODO: PUT this configuration stanza into nova class
nova_config { 'DEFAULT/resume_guests_state_on_host_boot': value => hiera('resume_guests_state_on_host_boot')}
nova_config { 'DEFAULT/use_cow_images': value => hiera('use_cow_images')}

# Configure monit watchdogs
# FIXME(bogdando) replace service_path and action to systemd, once supported
if $use_monit_real {
  monit::process { $nova_compute_name :
    ensure        => running,
    matching      => '/usr/bin/python /usr/bin/nova-compute',
    start_command => "${service_path} ${nova_compute_name} restart",
    stop_command  => "${service_path} ${nova_compute_name} stop",
    pidfile       => false,
  }
  if $::use_neutron {
    monit::process { $ovs_vswitchd_name :
      ensure        => running,
      start_command => "${service_path} ${ovs_vswitchd_name} restart",
      stop_command  => "${service_path} ${ovs_vswitchd_name} stop",
      pidfile       => '/var/run/openvswitch/ovs-vswitchd.pid',
    }
  } else {
    monit::process { $nova_network_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-network',
      start_command => "${service_path} ${nova_network_name} restart",
      stop_command  => "${service_path} ${nova_network_name} stop",
      pidfile       => false,
    }
    monit::process { $nova_api_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-api',
      start_command => "${service_path} ${nova_api_name} restart",
      stop_command  => "${service_path} ${nova_api_name} stop",
      pidfile       => false,
    }
  }
}

########################################################################


# vim: set ts=2 sw=2 et :
