#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
#
# === Parameters
#
# See params.pp
#
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [public_interface] Public interface used to route public traffic. Optional.
#   Defaults to false.
# [fixed_range] Range of ipv4 network for vms.
# [network_manager] Nova network manager to use.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [sql_connection] SQL connection information. Optional. Defaults to false
#   which indicates that exported resources will be used to determine connection
#   information.
# [nova_user_password] Nova service password.
#  [rabbit_nodes] RabbitMQ nodes or false. Optional. Defaults to false.
#  [rabbit_password] RabbitMQ password. Optional. Defaults to  'rabbit_pw',
#  [rabbit_user] RabbitMQ user. Optional. Defaults to 'nova',
#  [glance_api_servers] List of glance api servers of the form HOST:PORT
#    delimited by ':'. False indicates that the resource should be collected.
#    Optional. Defaults to false,
#  [libvirt_type] Underlying libvirt supported hypervisor.
#    Optional. Defaults to 'kvm',
#  [vncproxy_host] Host that serves as vnc proxy. Optional.
#    Defaults to false. False indicates that a vnc proxy should not be configured.
#  [vnc_enabled] Rather vnc console should be enabled.
#    Optional. Defaults to 'true',
# [verbose] Rather to print more verbose (INFO+) output. If non verbose and non debug, would give syslog_log_level (default is WARNING) output. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option. Optional. Defaults to false.
#  [manage_volumes] Rather nova-volume should be enabled on this compute node.
#    Optional. Defaults to false.
#  [nova_volumes] Name of volume group in which nova-volume will create logical volumes.
#    Optional. Defaults to nova-volumes.
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.
# [ssh_private_key] path to private ssh key temporary location on this server where it was uploaded or generated
# [ssh_public_key] path to public ssh key temporary location on this server where it was uploaded or generated
#
# class { 'openstack::nova::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
#   nova_user_password => 'changeme',
# }

class openstack::mongo (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Network
  # DB
  $sql_connection                = false,
  # Nova
  $purge_nova_config             = false,
  # AMQP
  $queue_provider                = 'rabbitmq',
  # Rabbit
  $rabbit_nodes                  = false,
  $rabbit_password               = 'rabbit_pw',
  $rabbit_host                   = false,
  $rabbit_user                   = 'nova',
  $rabbit_ha_virtual_ip          = false,
  # Qpid
  $qpid_nodes                    = false,
  $qpid_password                 = 'qpid_pw',
  $qpid_host                     = false,
  $qpid_user                     = 'nova',
  # Glance
  $glance_api_servers            = undef,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = $internal_address,
  # General
  $enabled                       = true,
  $multi_host                    = false,
  $auto_assign_floating_ip       = false,
  $network_config                = {},
  $public_interface,
  $private_interface,
  $network_manager,
  $fixed_range                   = undef,
  # Quantum
  $quantum                       = false,
  $quantum_config                = {},
  # Ceilometer
  $ceilometer_user_password      = 'ceilometer_pass',
  # nova compute configuration parameters
  $verbose                       = false,
  $debug               = false,
  $service_endpoint              = '127.0.0.1',
  $ssh_private_key               = '/var/lib/astute/nova/nova',
  $ssh_public_key                = '/var/lib/astute/nova/nova.pub',
  $cache_server_ip               = ['127.0.0.1'],
  $cache_server_port             = '11211',
  # if the cinder management components should be installed
  $manage_volumes                = false,
  $nv_physical_volume            = undef,
  $cinder_volume_group           = 'cinder-volumes',
  $cinder                        = true,
  $cinder_user_password          = 'cinder_user_pass',
  $cinder_db_password            = 'cinder_db_pass',
  $cinder_db_user                = 'cinder',
  $cinder_db_dbname              = 'cinder',
  $cinder_iscsi_bind_addr        = false,
  $db_host                       = '127.0.0.1',
  $use_syslog                    = false,
  $syslog_log_facility           = 'LOCAL6',
  $syslog_log_facility_cinder    = 'LOCAL3',
  $syslog_log_facility_neutron   = 'LOCAL4',
  $syslog_log_level = 'WARNING',
  $nova_rate_limits              = undef,
  $cinder_rate_limits            = undef,
  $create_networks               = false,
  $state_path                    = '/var/lib/nova',
  $ceilometer                    = false,
  $ceilometer_metering_secret    = "ceilometer",
) {

  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port    => 27017,
    verbose => true,
    bind_ip => ['0.0.0.0'],
    replset => 'ceilometer',
    auth => true,
  }


}
# vim: set ts=2 sw=2 et :
