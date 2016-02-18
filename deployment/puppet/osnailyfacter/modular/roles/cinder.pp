notice('MODULAR: cinder.pp')

# Pulling hiera
$network_scheme   = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$cinder_hash                    = hiera_hash('cinder_hash', {})
$storage_address                = get_network_role_property('cinder/iscsi', 'ipaddr')
$public_vip                     = hiera('public_vip')
$management_vip                 = hiera('management_vip')
$primary_controller             = hiera('primary_controller')
$use_neutron                    = hiera('use_neutron', false)
$mp_hash                        = hiera('mp')
$verbose                        = pick($cinder_hash['verbose'], true)
$debug                          = pick($cinder_hash['debug'], hiera('debug', true))
$use_monit                      = false
$auto_assign_floating_ip        = hiera('auto_assign_floating_ip', false)
$node_volumes                   = hiera('node_volumes', [])
$storage_hash                   = hiera_hash('storage_hash', {})
$vcenter_hash                   = hiera('vcenter', {})
$nova_hash                      = hiera_hash('nova_hash', {})
$mysql_hash                     = hiera_hash('mysql', {})
$rabbit_hash                    = hiera_hash('rabbit_hash', {})
$glance_hash                    = hiera_hash('glance_hash', {})
$keystone_hash                  = hiera_hash('keystone_hash', {})
$ceilometer_hash                = hiera_hash('ceilometer_hash',{})
$access_hash                    = hiera('access', {})
$neutron_mellanox               = hiera('neutron_mellanox', false)
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
$use_stderr                     = hiera('use_stderr', false)
$use_syslog                     = hiera('use_syslog', true)
$syslog_log_facility_glance     = hiera('syslog_log_facility_glance', 'LOG_LOCAL2')
$syslog_log_facility_cinder     = hiera('syslog_log_facility_cinder', 'LOG_LOCAL3')
$syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
$syslog_log_facility_nova       = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$syslog_log_facility_keystone   = hiera('syslog_log_facility_keystone', 'LOG_LOCAL7')
$syslog_log_facility_sahara     = hiera('syslog_log_facility_sahara','LOG_LOCAL0')
$syslog_log_facility_ceph       = hiera('syslog_log_facility_ceph','LOG_LOCAL0')

$keystone_user                  = pick($cinder_hash['user'], 'cinder')
$keystone_tenant                = pick($cinder_hash['tenant'], 'services')

$db_type      = 'mysql'
$db_host      = pick($cinder_hash['db_host'], hiera('database_vip'))
$db_user      = pick($cinder_hash['db_user'], 'cinder')
$db_password  = $cinder_hash[db_password]
$db_name      = pick($cinder_hash['db_name'], 'cinder')
# LP#1526938 - python-mysqldb supports this, python-pymysql does not
if $::os_package_type == 'debian' {
  $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
} else {
  $extra_params = { 'charset' => 'utf8' }
}
$db_connection = os_database_connection({
  'dialect'  => $db_type,
  'host'     => $db_host,
  'database' => $db_name,
  'username' => $db_user,
  'password' => $db_password,
  'extra'    => $extra_params
})

$ssl_hash                       = hiera_hash('use_ssl', {})
$service_endpoint               = hiera('service_endpoint')

$keystone_auth_protocol         = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$keystone_auth_host             = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

$glance_protocol                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
$glance_endpoint                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])
$glance_internal_ssl            = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)
if $glance_internal_ssl {
  $glance_api_servers = "${glance_protocol}://${glance_endpoint}:9292"
} else {
  $glance_api_servers = hiera('glance_api_servers', "http://${management_vip}:9292")
}

$service_port = '5000'
$auth_uri     = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"

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

$queue_provider = hiera('queue_provider', 'rabbitmq')
$custom_mysql_setup_class='galera'

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

if (!empty(get_nodes_hash_by_roles($network_metadata, ['ceph-osd'])) or
  $storage_hash['volumes_ceph'] or
  $storage_hash['images_ceph'] or
  $storage_hash['objects_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}

if $use_neutron {
  $neutron_config = hiera('quantum_settings')
} else {
  $neutron_config = {}
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

if ! $use_neutron {
  $floating_ips_range = hiera('floating_network_range')
}
$floating_hash = {}

##CALCULATED PARAMETERS


##NO NEED TO CHANGE

$mountpoints = filter_hash($mp_hash,'point')

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

# Determine who should get the volume service

if (roles_include(['cinder']) and $storage_hash['volumes_lvm']) {
  $manage_volumes = 'iscsi'
  $physical_volumes = false
  $volume_backend_name = $storage_hash['volume_backend_names']['volumes_lvm']
} elsif roles_include(['cinder-vmware']) {
  $manage_volumes = 'vmdk'
  $physical_volumes = false
} elsif ($storage_hash['volumes_ceph']) {
  $manage_volumes = 'ceph'
  $physical_volumes = false
  $volume_backend_name = $storage_hash['volume_backend_names']['volumes_ceph']
} elsif (roles_include(['cinder-block-device']) and $storage_hash['volumes_block_device']) {
  $manage_volumes = 'fake'
  $physical_volumes = join(get_disks_list_by_role($node_volumes, 'cinder-block-device'), ',')
  $volume_backend_name = $storage_hash['volume_backend_names']['volumes_block_device']
} else {
  $physical_volumes = false
  $manage_volumes = false
  $volume_backend_name = false
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

# NOTE(bogdando) for controller nodes running Corosync with Pacemaker
#   we delegate all of the monitor functions to RA instead of monit.
if roles_include(['controller', 'primary-controller']) {
  $use_monit_real = false
} else {
  $use_monit_real = $use_monit
}

if $use_monit_real {
  # Configure service names for monit watchdogs and 'service' system path
  # FIXME(bogdando) replace service_path to systemd, once supported
  include ::nova::params
  include ::cinder::params
  include ::neutron::params
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

$multi_host = true
$mirror_type = 'external'
Exec { logoutput => true }


#################################################################
# we need to evaluate ceph here, because ceph notifies/requires
# other services that are declared in openstack manifests
if ($use_ceph and !$storage_hash['volumes_lvm'] and !roles_include(['cinder-vmware'])) {
  $primary_mons   = $controllers
  $primary_mon    = $controllers[0]['name']

  if ($use_neutron) {
    prepare_network_config(hiera_hash('network_scheme', {}))
    $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
    $ceph_public_network  = get_network_role_property('ceph/public', 'network')
  } else {
    $ceph_cluster_network = hiera('storage_network_range')
    $ceph_public_network = hiera('management_network_range')
  }

  class {'::ceph':
    primary_mon              => $primary_mon,
    mon_hosts                => nodes_with_roles(['primary-controller', 'controller', 'ceph-mon'], 'name'),
    mon_ip_addresses         => get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller', 'ceph-mon']), 'mgmt/vip'),
    cluster_node_address     => $public_vip,
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
    syslog_log_facility      => $syslog_log_facility_ceph,
    rgw_keystone_admin_token => $keystone_hash['admin_token'],
    ephemeral_ceph           => $storage_hash['ephemeral_ceph']
  }
}

#################################################################

include ::keystone::python

#FIXME(bogdando) notify services on python-amqp update, if needed
package { 'python-amqp':
  ensure => present
}

if roles_include(['controller', 'primary-controller']) {
  $bind_host = get_network_role_property('cinder/api', 'ipaddr')
} else {
  $bind_host = false
  # Configure auth_strategy on cinder node, if cinder and controller are
  # on the same node this parameter is configured by ::cinder::api
  cinder_config {
    'DEFAULT/auth_strategy': value => 'keystone';
  }
}

# NOTE(bogdando) deploy cinder volume node with disabled cinder-volume
#   service #LP1398817. The orchestration will start and enable it back
#   after the deployment is done.
class { '::openstack::cinder':
  enable_volumes       => false,
  sql_connection       => $db_connection,
  glance_api_servers   => $glance_api_servers,
  bind_host            => $bind_host,
  queue_provider       => $queue_provider,
  amqp_hosts           => hiera('amqp_hosts',''),
  amqp_user            => pick($rabbit_hash['user'], 'nova'),
  amqp_password        => $rabbit_hash['password'],
  rabbit_ha_queues     => hiera('rabbit_ha_queues', false),
  volume_group         => 'cinder',
  manage_volumes       => $manage_volumes,
  iser                 => $storage_hash['iser'],
  enabled              => true,
  iscsi_bind_host      => $storage_address,
  keystone_user        => $keystone_user,
  keystone_tenant      => $keystone_tenant,
  cinder_user_password => $cinder_hash[user_password],
  syslog_log_facility  => $syslog_log_facility_cinder,
  physical_volume      => $physical_volumes,
  volume_backend_name  => $volume_backend_name,
  debug                => $debug,
  verbose              => $verbose,
  use_stderr           => $use_stderr,
  use_syslog           => $use_syslog,
  max_retries          => $max_retries,
  max_pool_size        => $max_pool_size,
  max_overflow         => $max_overflow,
  idle_timeout         => $idle_timeout,
  notification_driver  => $ceilometer_hash['notification_driver'],
  vmware_host_ip       => $vcenter_hash['host_ip'],
  vmware_host_username => $vcenter_hash['vc_user'],
  vmware_host_password => $vcenter_hash['vc_password'],
  auth_uri             => $auth_uri,
  identity_uri         => $auth_uri,
}

cinder_config { 'keymgr/fixed_key':
  value => $cinder_hash[fixed_key];
}

# FIXME(bogdando) replace service_path and action to systemd, once supported
if $use_monit_real {
  monit::check::process { $cinder_volume_name :
    ensure        => running,
    matching      => '/usr/bin/python /usr/bin/cinder-volume',
    program_start => "${service_path} ${cinder_volume_name} restart",
    program_stop  => "${service_path} ${cinder_volume_name} stop",
    pidfile       => false,
  }
}
#################################################################

# vim: set ts=2 sw=2 et :
