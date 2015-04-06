notice('MODULAR: controller.pp')

# Pulling hiera
$public_vip                     = hiera('public_vip')
$management_vip                 = hiera('management_vip')
$internal_address               = hiera('internal_address')
$primary_controller             = hiera('primary_controller')
$storage_address                = hiera('storage_address')
$use_neutron                    = hiera('use_neutron', false)
$cinder_nodes_array             = hiera('cinder_nodes', [])
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$heat_hash                      = hiera('heat', {})
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
$cinder_hash                    = hiera('cinder', {})
$ceilometer_hash                = hiera('ceilometer',{})
$access_hash                    = hiera('access', {})
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
$nova_service_down_time         = hiera('nova_service_down_time')
$nova_report_interval           = hiera('nova_report_interval')

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

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

class { 'l23network' :
  use_ovs => $use_neutron
}

if $use_neutron {
  $neutron_config            = hiera('quantum_settings')
  $neutron_db_password       = $neutron_config['database']['passwd']
  $neutron_user_password     = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                  = $neutron_config['L2']['base_mac']
} else {
  $neutron_config     = {}
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

if !$rabbit_hash['user'] {
  $rabbit_hash['user'] = 'nova'
}

if ! $use_neutron {
  $floating_ips_range = hiera('floating_network_range')
}
$floating_hash = {}

# get cidr netmasks for VIPs
$primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')

##TODO: simply parse nodes array
$controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
$controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
$controller_storage_addresses = nodes_to_hash($controllers,'name','storage_address')
$controller_hostnames = keys($controller_internal_addresses)
$controller_nodes = ipsort(values($controller_internal_addresses))
$controller_node_public  = $public_vip
$controller_node_address = $management_vip
$roles = node_roles($nodes_hash, hiera('uid'))

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

Exec { logoutput => true }

if ($::mellanox_mode == 'ethernet') {
  $ml2_eswitch = $neutron_mellanox['ml2_eswitch']
  class { 'mellanox_openstack::controller':
    eswitch_vnic_type            => $ml2_eswitch['vnic_type'],
    eswitch_apply_profile_patch  => $ml2_eswitch['apply_profile_patch'],
  }
}

# TODO(bogdando) add monit zabbix services monitoring, if required
# NOTE(bogdando) for nodes with pacemaker, we should use OCF instead of monit

# BP https://blueprints.launchpad.net/mos/+spec/include-openstackclient
package { 'python-openstackclient' :
  ensure => installed,
}

# Reduce swapiness on controllers, see LP#1413702
sysctl::value { 'vm.swappiness':
  value => "10"
}

# vim: set ts=2 sw=2 et :
